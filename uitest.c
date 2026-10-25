#if defined(CID(send_to)) || defined(CID(alive_at))

#if defined(__linux__) && !defined(__OBJC__)
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>

typedef struct {
  char* display;
  u32 id;
} UitestRef;

static bool uitest_ref(Env e, Term display, Term id, UitestRef* ref) {
  u64 size = 0;
  ref->display = io_cstr(e, display, &size);
  ref->id = (u32)id;
  return size != 0 && memchr(ref->display, 0, size) == NULL && ref->id != 0;
}

typedef struct {
  Display* dpy;
  unsigned long first;
  int (*previous)(Display*, XErrorEvent*);
  int error;
} UitestTrap;

// This process-wide Xlib handler stays on Bend's immediate IO thread.
static UitestTrap* uitest_trap;

static int uitest_error(Display* dpy, XErrorEvent* error) {
  UitestTrap* trap = uitest_trap;
  if (dpy == trap->dpy && error->serial - trap->first
      < NextRequest(dpy) - trap->first) {
    if (trap->error == 0) {
      trap->error = error->error_code;
    }
    return 0;
  }
  return trap->previous(dpy, error);
}

static void uitest_begin(UitestTrap* trap, Display* dpy) {
  *trap = (UitestTrap){ .dpy = dpy, .first = NextRequest(dpy) };
  uitest_trap = trap;
  trap->previous = XSetErrorHandler(uitest_error);
}

static int uitest_finish(UitestTrap* trap) {
  XSync(trap->dpy, False);
  XCloseDisplay(trap->dpy);
  XSetErrorHandler(trap->previous);
  uitest_trap = NULL;
  return trap->error;
}

static u32 uitest_errno(int error) {
  return error == BadWindow || error == BadDrawable ? ENOENT
    : error == BadValue ? EINVAL : error == BadMatch ? EAGAIN : EIO;
}

#endif

#ifdef CID(send_to)

#if defined(__linux__) && !defined(__OBJC__)

typedef enum { UITEST_KEY, UITEST_CLICK, UITEST_CLOSE } UitestKind;

typedef struct {
  UitestKind kind;
  u32 code;
  u32 x;
  u32 y;
  u32 button;
  bool down;
} UitestPlan;

static bool uitest_event(Env e, Term value, UitestPlan* event) {
  if (term_aux(value) == CID(Key)) {
    Term fields[2];
    spare_free(e, cls_fit(2), ctr_take(e, value, 2, fields));
    // Base Event stores its Bool field as a flattened 0/1 word.
    *event = (UitestPlan){ .kind = UITEST_KEY, .code = (u32)fields[0],
      .down = fields[1] == 1 };
    return fields[1] <= 1;
  }
  if (term_aux(value) == CID(Mouse)) {
    Term fields[4];
    spare_free(e, cls_fit(4), ctr_take(e, value, 4, fields));
    *event = (UitestPlan){ .kind = UITEST_CLICK, .x = (u32)fields[0],
      .y = (u32)fields[1], .button = (u32)fields[2],
      .down = fields[3] == 1 };
    return fields[3] <= 1;
  }
  if (term_aux(value) == CID(Close)) {
    *event = (UitestPlan){ .kind = UITEST_CLOSE };
    term_sink(e, value);
    return true;
  }
  term_sink(e, value);
  return false;
}

static bool uitest_plan(Env e, Term values, UitestPlan* plan) {
  UitestPlan events[2] = {0};
  u32 count = 0;
  bool valid = true;
  while (term_aux(values) == CID(Con) && count < 2) {
    Term fields[2];
    spare_free(e, cls_fit(2), ctr_take(e, values, 2, fields));
    valid = uitest_event(e, fields[0], &events[count]) && valid;
    count += 1;
    values = fields[1];
  }
  valid = term_aux(values) == CID(Nil) && valid;
  term_sink(e, values);
  if (!valid || count == 0) {
    return false;
  }
  *plan = events[0];
  if (plan->kind == UITEST_CLOSE) {
    return count == 1;
  }
  if (count != 2 || events[1].kind != plan->kind
      || !plan->down || events[1].down) {
    return false;
  }
  if (plan->kind == UITEST_KEY) {
    return events[1].code == plan->code;
  }
  return plan->button == 0 && events[1].button == 0
    && events[1].x == plan->x && events[1].y == plan->y;
}

// Keep this decoder identical to Bend 2.0.39's window_key.
static const u32 uitest_keys[][2] = {
  { XK_BackSpace, 127 },   { XK_Up,        63232 }, { XK_Down,      63233 },
  { XK_Left,      63234 }, { XK_Right,     63235 }, { XK_Insert,    63271 },
  { XK_Delete,    63272 }, { XK_Home,      63273 }, { XK_End,       63275 },
  { XK_Page_Up,   63276 }, { XK_Page_Down, 63277 }, { XK_Super_R,   65590 },
  { XK_Super_L,   65591 }, { XK_Shift_L,   65592 }, { XK_Caps_Lock, 65593 },
  { XK_Alt_L,     65594 }, { XK_Control_L, 65595 }, { XK_Shift_R,   65596 },
  { XK_Alt_R,     65597 }, { XK_Control_R, 65598 }, { XK_ISO_Left_Tab, 25 },
};

static u32 uitest_key(XKeyEvent* ev) {
  char c[8];
  KeySym ks = 0;
  ev->state &= ShiftMask | LockMask;
  int n = XLookupString(ev, c, sizeof c, &ks, NULL);
  for (u32 i = 0; i < sizeof uitest_keys / sizeof *uitest_keys; i += 1) {
    if (uitest_keys[i][0] == ks) {
      return uitest_keys[i][1];
    }
  }
  if (ks >= XK_F1 && ks <= XK_F12) {
    return 63236 + (u32)(ks - XK_F1);
  }
  if (n == 1) {
    return (u8)c[0] >= 'A' && (u8)c[0] <= 'Z' ? (u8)c[0] + 32 : (u8)c[0];
  }
  return 65536 + ev->keycode;
}

static bool uitest_key_domain(u32 code, int min, int max) {
  if (code >= 'A' && code <= 'Z') {
    return false;
  }
  if (code <= 255 || (code >= 63236 && code <= 63247)
      || (code >= 65536 + min && code <= 65536 + max)) {
    return true;
  }
  for (u32 i = 0; i < sizeof uitest_keys / sizeof *uitest_keys; i += 1) {
    if (uitest_keys[i][1] == code) {
      return true;
    }
  }
  return false;
}

static bool uitest_resolve_key(Display* dpy, Window win, Window root,
    u32 code, XKeyEvent* out) {
  int min, max;
  XDisplayKeycodes(dpy, &min, &max);
  const unsigned int states[] = {0, ShiftMask, LockMask, ShiftMask | LockMask};
  for (u32 s = 0; s < sizeof states / sizeof *states; s += 1) {
    for (int keycode = min; keycode <= max; keycode += 1) {
      XKeyEvent event = { .type = KeyPress, .display = dpy, .window = win,
        .root = root, .subwindow = None, .time = CurrentTime,
        .state = states[s], .keycode = (unsigned int)keycode,
        .same_screen = True };
      XKeyEvent decoded = event;
      if (uitest_key(&decoded) == code) {
        *out = event;
        return true;
      }
    }
  }
  return false;
}

static bool uitest_close_supported(Display* dpy, Window win, Atom del) {
  Atom* protocols = NULL;
  int count = 0;
  bool supported = false;
  if (XGetWMProtocols(dpy, win, &protocols, &count)) {
    for (int i = 0; i < count; i += 1) {
      supported = supported || protocols[i] == del;
    }
  }
  if (protocols != NULL) {
    XFree(protocols);
  }
  return supported;
}

#endif

static Term uitest_send_run(Env e, Term* f, IoWork* work) {
#if defined(__linux__) && !defined(__OBJC__)
  UitestRef ref = {0};
  UitestPlan plan = {0};
  bool ref_valid = uitest_ref(e, f[0], f[1], &ref);
  bool plan_valid = uitest_plan(e, f[2], &plan);
  if (!ref_valid || !plan_valid) {
    free(ref.display);
    return io_fail(e, EINVAL, "UITest.send: invalid window reference or event plan");
  }
  Display* dpy = XOpenDisplay(ref.display);
  free(ref.display);
  if (dpy == NULL) {
    return io_fail(e, ENOENT, "UITest.send: cannot open the reference's X11 display");
  }
  UitestTrap trap;
  uitest_begin(&trap, dpy);
  u32 code = 0;
  const char* why = NULL;
  char unavailable[96];
  XWindowAttributes attrs;
  XEvent down = {0}, up = {0};
  long down_mask = NoEventMask, up_mask = NoEventMask;
  bool pair = plan.kind != UITEST_CLOSE;
  do {
    if (!XGetWindowAttributes(dpy, ref.id, &attrs)) {
      code = EIO;
      why = "UITest.send: cannot query the target window";
      break;
    }
    if (attrs.class != InputOutput) {
      code = ENOTSUP;
      why = "UITest.send: target is not an input/output window";
      break;
    }
    if (plan.kind == UITEST_KEY) {
      int min, max;
      XDisplayKeycodes(dpy, &min, &max);
      if (!uitest_key_domain(plan.code, min, max)) {
        code = EINVAL;
        why = "UITest.key: invalid Bend key code";
        break;
      }
      down_mask = KeyPressMask;
      up_mask = KeyReleaseMask;
      if (!uitest_resolve_key(dpy, ref.id, attrs.root, plan.code, &down.xkey)) {
        code = ENOTSUP;
        snprintf(unavailable, sizeof unavailable,
          "UITest.key: Bend key code %u is unavailable on the current layout", plan.code);
        why = unavailable;
        break;
      }
      up = down;
      up.xkey.type = KeyRelease;
    } else if (plan.kind == UITEST_CLICK) {
      if (plan.x > INT16_MAX || plan.y > INT16_MAX || attrs.width <= 0
          || attrs.height <= 0 || plan.x >= (u32)attrs.width
          || plan.y >= (u32)attrs.height) {
        code = EINVAL;
        why = "UITest.click: coordinates must be inside the client and fit signed 16 bits";
        break;
      }
      down_mask = ButtonPressMask;
      up_mask = ButtonReleaseMask;
      down.xbutton = (XButtonEvent){ .type = ButtonPress, .display = dpy,
        .window = ref.id, .root = attrs.root, .subwindow = None,
        .time = CurrentTime, .x = (int)plan.x, .y = (int)plan.y,
        .button = Button1, .same_screen = True };
      up = down;
      up.xbutton.type = ButtonRelease;
      up.xbutton.state = Button1Mask;
    } else {
      Atom del = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
      if (!uitest_close_supported(dpy, ref.id, del)) {
        code = ENOTSUP;
        why = "UITest.request_close: target does not support WM_DELETE_WINDOW";
        break;
      }
      down.xclient = (XClientMessageEvent){ .type = ClientMessage,
        .display = dpy, .window = ref.id,
        .message_type = XInternAtom(dpy, "WM_PROTOCOLS", False), .format = 32 };
      down.xclient.data.l[0] = del;
      down.xclient.data.l[1] = CurrentTime;
    }
    if (pair && (attrs.all_event_masks & (down_mask | up_mask))
        != (down_mask | up_mask)) {
      code = ENOTSUP;
      why = "UITest.send: target does not select both input event edges";
      break;
    }
    XSync(dpy, False);
    if (trap.error != 0) {
      break;
    }
    bool sent_down = XSendEvent(dpy, ref.id, False, down_mask, &down) != 0;
    bool sent_up = !pair || XSendEvent(dpy, ref.id, False, up_mask, &up) != 0;
    if (!sent_down || !sent_up) {
      code = EIO;
      why = "UITest.send: XSendEvent rejected an event";
    }
  } while (false);
  int error = uitest_finish(&trap);
  if (error != 0) {
    code = uitest_errno(error);
    why = "UITest.send: X11 protocol error";
  }
  return code == 0 ? io_done(e, term_pak(CID(Unit), 0)) : io_fail(e, code, why);
#else
  term_sink(e, f[0]);
  term_sink(e, f[2]);
  return io_fail(e, ENOTSUP, "UITest.send: X11 test effects are unavailable on this backend");
#endif
}

static void __attribute__((constructor)) uitest_send_use(void) {
  io_eff(CID(send_to), uitest_send_run);
}

#endif

#ifdef CID(alive_at)

static Term uitest_alive_run(Env e, Term* f, IoWork* work) {
#if defined(__linux__) && !defined(__OBJC__)
  UitestRef ref = {0};
  if (!uitest_ref(e, f[0], f[1], &ref)) {
    free(ref.display);
    return io_fail(e, EINVAL, "UITest.alive: invalid window reference");
  }
  Display* dpy = XOpenDisplay(ref.display);
  free(ref.display);
  if (dpy == NULL) {
    return io_fail(e, ENOENT, "UITest.alive: cannot open the reference's X11 display");
  }
  UitestTrap trap;
  uitest_begin(&trap, dpy);
  XWindowAttributes attrs;
  bool exists = XGetWindowAttributes(dpy, ref.id, &attrs) != 0;
  int error = uitest_finish(&trap);
  if (error == BadWindow) {
    return io_done(e, term_pak(CID(False), 0));
  }
  if (error != 0 || !exists) {
    return io_fail(e, error == 0 ? EIO : uitest_errno(error),
      "UITest.alive: X11 window query failed");
  }
  return io_done(e, term_pak(CID(True), 0));
#else
  term_sink(e, f[0]);
  return io_fail(e, ENOTSUP, "UITest.alive: X11 test effects are unavailable on this backend");
#endif
}

static void __attribute__((constructor)) uitest_alive_use(void) {
  io_eff(CID(alive_at), uitest_alive_run);
}

#endif

#endif
