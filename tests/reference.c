#if defined(__linux__) && !defined(__OBJC__)
#include <X11/Xlib.h>
#include <X11/Xutil.h>

static u32 window_key(XKeyEvent* event);
#endif

static Term uitest_reference_watch_close_run(Env e, Term* f, IoWork* work) {
#if defined(__linux__) && !defined(__OBJC__)
  u64 length = 0;
  char* display = io_cstr(e, f[0], &length);
  Display* dpy = XOpenDisplay(display);
  free(display);
  if (dpy == NULL) {
    err_fail("close observation cannot open its display");
  }
  XSelectInput(dpy, (u32)f[1], StructureNotifyMask);
  XSync(dpy, False);
  // Keep the observer affine in Bend; carry its pointer as two U32 words.
  u64 address = (u64)(uintptr_t)dpy;
  return io_node(e, CID(CloseWatch), (u32)address, (u32)(address >> 32));
#else
  err_fail("close observation requires native X11");
  return 0;
#endif
}

static void __attribute__((constructor)) uitest_reference_watch_close_use(void) {
  io_eff(CID(watch_close_at), uitest_reference_watch_close_run);
}

static Term uitest_reference_await_close_run(Env e, Term* f, IoWork* work) {
#if defined(__linux__) && !defined(__OBJC__)
  Term fields[2];
  spare_free(e, cls_fit(2), ctr_take(e, f[0], 2, fields));
  Display* dpy = (Display*)(uintptr_t)((u64)fields[1] << 32 | fields[0]);
  struct pollfd fd = { .fd = ConnectionNumber(dpy), .events = POLLIN };
  u64 deadline = io_until(5000);
  while (true) {
    while (XPending(dpy)) {
      XEvent event;
      XNextEvent(dpy, &event);
      if (event.type == DestroyNotify) {
        XCloseDisplay(dpy);
        return term_pak(CID(Unit), 0);
      }
    }
    u64 now = io_tick();
    if (now >= deadline || poll(&fd, 1, (int)((deadline - now + 999999) / 1000000)) <= 0) {
      XCloseDisplay(dpy);
      err_fail("Window.close did not produce DestroyNotify within five seconds");
    }
  }
#else
  err_fail("close observation requires native X11");
  return 0;
#endif
}

static void __attribute__((constructor)) uitest_reference_await_close_use(void) {
  io_eff(CID(await_close), uitest_reference_await_close_run);
}

static Term uitest_reference_codes_run(Env e, Term* f, IoWork* work) {
  u64 length = 0;
  char* display = io_cstr(e, f[0], &length);
  Term codes = term_pak(CID(Nil), 0);
#if defined(__linux__) && !defined(__OBJC__)
  Display* dpy = XOpenDisplay(display);
  if (dpy == NULL) {
    free(display);
    err_fail("reference test cannot open its display");
  }
  int min, max;
  XDisplayKeycodes(dpy, &min, &max);
  const unsigned int states[] = {0, ShiftMask, LockMask, ShiftMask | LockMask};
  u32 unique[1024];
  u32 count = 0;
  for (u32 state = 0; state < 4; state += 1) {
    for (int keycode = min; keycode <= max; keycode += 1) {
      XKeyEvent event = {.type = KeyPress, .display = dpy,
        .window = (u32)f[1], .root = DefaultRootWindow(dpy),
        .keycode = (unsigned int)keycode, .state = states[state],
        .same_screen = True};
      u32 code = window_key(&event);
      bool seen = false;
      for (u32 i = 0; i < count; i += 1) {
        seen |= unique[i] == code;
      }
      if (!seen) {
        unique[count++] = code;
      }
    }
  }
  for (u32 i = count; i > 0; i -= 1) {
    codes = io_node(e, CID(Con), unique[i - 1], codes);
  }
  printf("reference keymap: %u codes\n", count);
  XCloseDisplay(dpy);
#endif
  free(display);
  return codes;
}

static void __attribute__((constructor)) uitest_reference_codes_use(void) {
  io_eff(CID(codes), uitest_reference_codes_run);
}

static Term uitest_reference_arrange_run(Env e, Term* f, IoWork* work) {
  u64 length = 0;
  char* display = io_cstr(e, f[0], &length);
#if defined(__linux__) && !defined(__OBJC__)
  Display* dpy = XOpenDisplay(display);
  if (dpy == NULL) {
    free(display);
    err_fail("reference test cannot arrange its windows");
  }
  XMoveWindow(dpy, (u32)f[1], 32, 32);
  XMoveWindow(dpy, (u32)f[2], 256, 32);
  XSync(dpy, False);
  XCloseDisplay(dpy);
#endif
  free(display);
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) uitest_reference_arrange_use(void) {
  io_eff(CID(arrange), uitest_reference_arrange_run);
}

static Term uitest_reference_snapshot_run(Env e, Term* f, IoWork* work) {
  u64 length = 0;
  char* display = io_cstr(e, f[0], &length);
  unsigned long focus = 0;
  int x = 0, y = 0;
  unsigned int state = 0;
  char keymap[32] = {0};
#if defined(__linux__) && !defined(__OBJC__)
  Display* dpy = XOpenDisplay(display);
  if (dpy == NULL) {
    free(display);
    err_fail("reference test cannot query its input state");
  }
  Window focused, root, child;
  int revert, rx, ry, wx, wy;
  unsigned int mask;
  XGetInputFocus(dpy, &focused, &revert);
  if (!XQueryPointer(dpy, DefaultRootWindow(dpy), &root, &child,
      &rx, &ry, &wx, &wy, &mask)) {
    err_fail("reference test cannot query its pointer");
  }
  XQueryKeymap(dpy, keymap);
  focus = focused;
  x = rx;
  y = ry;
  state = mask;
  XCloseDisplay(dpy);
#endif
  free(display);
  char snapshot[192];
  const char hex[] = "0123456789abcdef";
  int size = snprintf(snapshot, sizeof snapshot, "%lu,%d,%d,%u,", focus, x, y, state);
  for (u32 i = 0; i < 32; i += 1) {
    snapshot[size++] = hex[((u8)keymap[i]) >> 4];
    snapshot[size++] = hex[((u8)keymap[i]) & 15];
  }
  return io_str(e, snapshot, (u64)size);
}

static void __attribute__((constructor)) uitest_reference_snapshot_use(void) {
  io_eff(CID(snapshot), uitest_reference_snapshot_run);
}
