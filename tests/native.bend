import Base
import 0x493e83fed22415cb35e84da752fefdef/capture.bend as Capture
import 0x3d4f2512cce00e5099d03d9e1b3b9ae1/winref.bend as WinRef
import ../uitest.bend as UITest
import ./assert.bend as Assert
import ./reference.bend as Reference

def same_bool(a: Bool, b: Bool) -> Bool:
  U32.is_eq(Bool.to_u32(a), Bool.to_u32(b))

def same_event(a: Event, b: Event) -> Bool:
  match a b:
    case Key{ac, ad} Key{bc, bd}:
      U32.is_eq(ac, bc) && same_bool(ad, bd)
    case Mouse{ax, ay, ab, ad} Mouse{bx, by, bb, bd}:
      U32.is_eq(ax, bx) && U32.is_eq(ay, by) && U32.is_eq(ab, bb) && same_bool(ad, bd)
    case Close{} Close{}:
      True{}
    case other_a other_b:
      False{}

def same_events(a: List<Event>, b: List<Event>) -> Bool:
  match a b:
    case Nil{} Nil{}:
      True{}
    case Con{ah, at} Con{bh, bt}:
      same_event(ah, bh) && same_events(at, bt)
    case other_a other_b:
      False{}

def input_events(events: List<Event>) -> List<Event>:
  match events:
    case Nil{}:
      Nil{}
    case Key{code, down} <> rest:
      Key{code, down} <> input_events(rest)
    case Mouse{x, y, button, down} <> rest:
      Mouse{x, y, button, down} <> input_events(rest)
    case Close{} <> rest:
      Close{} <> input_events(rest)
    case other <> rest:
      input_events(rest)

def expected() -> List<Event>:
  [Key{97, True{}}, Key{97, False{}},
   Key{13, True{}}, Key{13, False{}},
   Key{63234, True{}}, Key{63234, False{}},
   Key{63236, True{}}, Key{63236, False{}},
   Key{33, True{}}, Key{33, False{}},
   Key{127, True{}}, Key{127, False{}},
   Key{65592, True{}}, Key{65592, False{}},
   Mouse{23, 17, 0, True{}}, Mouse{23, 17, 0, False{}},
   Mouse{0, 0, 0, True{}}, Mouse{0, 0, 0, False{}},
   Mouse{95, 63, 0, True{}}, Mouse{95, 63, 0, False{}}, Close{}]

def roundtrip_codes(codes: List<U32>, +ref: WinRef.WindowRef) -> IO(List<Event>):
  match codes:
    case Nil{}:
      IO.pure(List<Event>, [])
    case Con{+code, rest}:
      do IO<List<Event>>:
        sent : Unit <- IO.try(Unit, UITest.key(ref, code))
        expected : List<Event> <- roundtrip_codes(rest, ref)
        return Key{code, True{}} <> Key{code, False{}} <> expected

def first_pixel(q: Array<U32> & U32) -> U32:
  (pixels, value) = q
  value

def expired(+ref: WinRef.WindowRef) -> IO(Unit):
  do IO<Unit>:
    alive : Result<&1, &1, U32 & String, Bool> <- UITest.alive(ref)
    Assert.check(Assert.success_bool(False{}, alive), "closed exported reference is no longer alive")
    keyed : Result<&1, &1, U32 & String, Unit> <- UITest.key(ref, 97)
    Assert.check(Assert.error_unit(2, keyed), "key on stale reference returns ENOENT")
    clicked : Result<&1, &1, U32 & String, Unit> <- UITest.click(ref, 0, 0)
    Assert.check(Assert.error_unit(2, clicked), "click on stale reference returns ENOENT")
    closed : Result<&1, &1, U32 & String, Unit> <- UITest.request_close(ref)
    Assert.check(Assert.error_unit(2, closed), "close on stale reference returns ENOENT")
    missing : Result<&1, &1, U32 & String, Bool> <- UITest.alive(WinRef.X11WindowRef{":65530", 123})
    Assert.check(Assert.error_bool(2, missing), "missing display is an error")
    empty : Result<&1, &1, U32 & String, Bool> <- UITest.alive(WinRef.X11WindowRef{"", 123})
    Assert.check(Assert.error_bool(22, empty), "empty display never substitutes DISPLAY")
    nul : Result<&1, &1, U32 & String, Bool> <- UITest.alive(WinRef.X11WindowRef{SCon{Char.from_u32(0), ":1"}, 123})
    Assert.check(Assert.error_bool(22, nul), "embedded NUL in display is rejected")
    zero : Result<&1, &1, U32 & String, Bool> <- UITest.alive(WinRef.X11WindowRef{":65530", 0})
    Assert.check(Assert.error_bool(22, zero), "zero window ID is rejected before opening display")
    IO.print("native UI tests: OK")

def isolated(ref: WinRef.WindowRef, window: Window, q: Window & Image & List<Event>) -> IO(Unit):
  (other, image, events) = q
  do IO<Unit>:
    Assert.check(same_events(input_events(events), []), "another window receives no injected input")
    Window.close(other)
    Window.close(window)
    expired(ref)

def captured(ref: WinRef.WindowRef, other: Window,
  q: Window & Result<&1, &1, U32 & String, Capture.Capture>) -> IO(Unit):
  (window, result) = q
  match result:
    case Done{Capture.Capture{width, height, pixels}}:
      do IO<Unit>:
        Assert.check(U32.is_eq(width, 96) && U32.is_eq(height, 64), "capture keeps exact client dimensions")
        Assert.check(U32.is_eq(first_pixel(Array.get(U32, pixels, 0)), 1122867), "capture reads the frame drawn after injection")
        IO.bind(Window & Image & List<Event>, Unit, Window.frame(other, Pix{0}), isolated(ref, window))
    case Fail{error}:
      do IO<Unit>:
        Window.close(other)
        Window.close(window)
        IO.die(Unit, 1, "FAIL: Window.capture after injection")

def keymap_observed(ref: WinRef.WindowRef, other: Window, expected: List<Event>,
  q: Window & Image & List<Event>) -> IO(Unit):
  (window, image, events) = q
  do IO<Unit>:
    Assert.check(same_events(input_events(events), expected), "every code produced by the upstream receiver round-trips through UITest.key")
    IO.bind(Window & Result<&1, &1, U32 & String, Capture.Capture>, Unit, Capture.Window.capture(window), captured(ref, other))

def observed(+ref: WinRef.WindowRef, other: Window, before: String,
  q: Window & Image & List<Event>) -> IO(Unit):
  (window, image, events) = q
  do IO<Unit>:
    Assert.check(same_events(input_events(events), expected()), "Window.frame observes exact ordered key, click, and close events")
    live : Bool <- IO.try(Bool, UITest.alive(ref))
    Assert.check(live, "request_close leaves affine owner alive")
    after : String <- Reference.input_state(ref)
    Assert.check(String.eq(before, after), "input injection preserves pointer, focus, and global key state")
    codes : List<U32> <- Reference.key_codes(ref)
    expected : List<Event> <- roundtrip_codes(codes, ref)
    IO.bind(Window & Image & List<Event>, Unit, Window.frame(window, Pix{1122867}), keymap_observed(ref, other, expected))

def exercise(+ref: WinRef.WindowRef, window: Window, other: Window) -> IO(Unit):
  do IO<Unit>:
    before : String <- Reference.input_state(ref)
    live : Bool <- IO.try(Bool, UITest.alive(ref))
    Assert.check(live, "exported window is alive")
    a : Unit <- IO.try(Unit, UITest.key(ref, 97))
    enter : Unit <- IO.try(Unit, UITest.key(ref, 13))
    left : Unit <- IO.try(Unit, UITest.key(ref, 63234))
    f1 : Unit <- IO.try(Unit, UITest.key(ref, 63236))
    punctuation : Unit <- IO.try(Unit, UITest.key(ref, 33))
    backspace : Unit <- IO.try(Unit, UITest.key(ref, 127))
    shift : Unit <- IO.try(Unit, UITest.key(ref, 65592))
    click : Unit <- IO.try(Unit, UITest.click(ref, 23, 17))
    origin : Unit <- IO.try(Unit, UITest.click(ref, 0, 0))
    corner : Unit <- IO.try(Unit, UITest.click(ref, 95, 63))
    bad_x : Result<&1, &1, U32 & String, Unit> <- UITest.click(ref, 96, 0)
    Assert.check(Assert.error_unit(22, bad_x), "x equal to width is rejected")
    bad_y : Result<&1, &1, U32 & String, Unit> <- UITest.click(ref, 0, 64)
    Assert.check(Assert.error_unit(22, bad_y), "y equal to height is rejected")
    overflow : Result<&1, &1, U32 & String, Unit> <- UITest.click(ref, 4294967295, 0)
    Assert.check(Assert.error_unit(22, overflow), "oversized coordinates are rejected")
    bad_key : Result<&1, &1, U32 & String, Unit> <- UITest.key(ref, 4294967295)
    Assert.check(Assert.error_unit(22, bad_key), "unknown key code is rejected")
    upper : Result<&1, &1, U32 & String, Unit> <- UITest.key(ref, 65)
    Assert.check(Assert.error_unit(22, upper), "uppercase code is rejected rather than silently normalized")
    incomplete : Result<&1, &1, U32 & String, Unit> <- UITest.send(ref, [Key{97, True{}}])
    Assert.check(Assert.error_unit(22, incomplete), "incomplete plan is rejected before sending")
    mismatched : Result<&1, &1, U32 & String, Unit> <- UITest.send(ref, [Key{97, True{}}, Key{98, False{}}])
    Assert.check(Assert.error_unit(22, mismatched), "mismatched key pair is rejected before sending")
    close : Unit <- IO.try(Unit, UITest.request_close(ref))
    IO.bind(Window & Image & List<Event>, Unit, Window.frame(window, Pix{1122867}), observed(ref, other, before))

def exported(other_ref: WinRef.WindowRef, other: Window,
  q: Window & Result<&1, &1, U32 & String, WinRef.WindowRef>) -> IO(Unit):
  (window, result) = q
  match result:
    case Done{+ref}:
      do IO<Unit>:
        Reference.separate(ref, other_ref)
        exercise(ref, window, other)
    case Fail{error}:
      do IO<Unit>:
        Window.close(other)
        Window.close(window)
        IO.die(Unit, 1, "FAIL: export reference")

def exported_other(window: Window,
  q: Window & Result<&1, &1, U32 & String, WinRef.WindowRef>) -> IO(Unit):
  (other, result) = q
  match result:
    case Done{other_ref}:
      IO.bind(Window & Result<&1, &1, U32 & String, WinRef.WindowRef>, Unit,
        WinRef.WinRef.export(window), exported(other_ref, other))
    case Fail{error}:
      do IO<Unit>:
        Window.close(other)
        Window.close(window)
        IO.die(Unit, 1, "FAIL: export second reference")

def second(window: Window, result: Result<&1, &1, U32 & String, Window>) -> IO(Unit):
  match result:
    case Done{other}:
      IO.bind(Window & Result<&1, &1, U32 & String, WinRef.WindowRef>, Unit, WinRef.WinRef.export(other), exported_other(window))
    case Fail{error}:
      do IO<Unit>:
        Window.close(window)
        IO.die(Unit, 1, "FAIL: open second window")

def opened(result: Result<&1, &1, U32 & String, Window>) -> IO(Unit):
  match result:
    case Done{window}:
      IO.bind(Result<&1, &1, U32 & String, Window>, Unit, Window.open("UITest isolation", 96, 64), second(window))
    case Fail{error}:
      IO.die(Unit, 1, "FAIL: open test window. Run under X11 or xvfb-run.")

def main() -> IO(Unit):
  IO.bind(Result<&1, &1, U32 & String, Window>, Unit, Window.open("UITest native", 96, 64), opened)
