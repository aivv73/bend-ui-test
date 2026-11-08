import Base
import 0xc49b12025f945d56de002cde2237ecc5/winref.bend as WinRef
import ../uitest.bend as UITest

def report(ok: Bool) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("UITest smoke: OK")
    case False{}:
      IO.die(Unit, 1, "UITest smoke: FAIL")

def has_close(events: List<Event>) -> Bool:
  match events:
    case Nil{}:
      False{}
    case Close{} <> rest:
      True{}
    case event <> rest:
      has_close(rest)

def finished(q: Window & Image & List<Event>) -> IO(Unit):
  (window, image, events) = q
  do IO<Unit>:
    Window.close(window)
    report(has_close(events))

def exported(q: Window & Result<&1, &1, U32 & String, WinRef.WindowRef>) -> IO(Unit):
  (window, result) = q
  match result:
    case Done{+ref}:
      do IO<Unit>:
        keyed : Unit <- IO.try(Unit, UITest.key(ref, 97))
        clicked : Unit <- IO.try(Unit, UITest.click(ref, 24, 18))
        closing : Unit <- IO.try(Unit, UITest.request_close(ref))
        IO.bind(Window & Image & List<Event>, Unit,
          Window.frame(window, Pix{3368601}), finished)
    case Fail{error}:
      do IO<Unit>:
        Window.close(window)
        IO.die(Unit, 1, "WinRef.export failed")

def main() -> IO(Unit):
  do IO<Unit>:
    window : Window <- IO.try(Window, Window.open("UITest smoke", 160, 120))
    IO.bind(Window & Result<&1, &1, U32 & String, WinRef.WindowRef>, Unit,
      WinRef.WinRef.export(window), exported)
