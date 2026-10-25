import Base
import 0x3d4f2512cce00e5099d03d9e1b3b9ae1/winref.bend as WinRef
import ../uitest.bend as UITest
import ./assert.bend as Assert

def main() -> IO(Unit):
  do IO<Unit>:
    keyed : Result<&1, &1, U32 & String, Unit> <- UITest.key(WinRef.X11WindowRef{":1", 123}, 97)
    Assert.check(Assert.error_unit(95, keyed), "JS key reports ENOTSUP")
    clicked : Result<&1, &1, U32 & String, Unit> <- UITest.click(WinRef.X11WindowRef{":1", 123}, 4, 5)
    Assert.check(Assert.error_unit(95, clicked), "JS click reports ENOTSUP")
    closed : Result<&1, &1, U32 & String, Unit> <- UITest.request_close(WinRef.X11WindowRef{":1", 123})
    Assert.check(Assert.error_unit(95, closed), "JS close reports ENOTSUP")
    alive : Result<&1, &1, U32 & String, Bool> <- UITest.alive(WinRef.X11WindowRef{":1", 123})
    Assert.check(Assert.error_bool(95, alive), "JS alive reports ENOTSUP")
    IO.print("JS UI tests: OK")
