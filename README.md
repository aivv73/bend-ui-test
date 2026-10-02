# Bend UI test

This library sends key presses, clicks, and close requests to a window in the Bend fork using `WindowRef`.
Obtain the reference through `Window.export_ref`. The application retains ownership of `Window`.

```python
import Base
import ./uitest.bend as UITest

def drive(+ref: WindowRef) -> IO(Unit):
  do IO<Unit>:
    keyed : Unit <- IO.try(Unit, UITest.key(ref, 97))
    clicked : Unit <- IO.try(Unit, UITest.click(ref, 24, 18))
    closing : Unit <- IO.try(Unit, UITest.request_close(ref))
    alive : Bool <- IO.try(Bool, UITest.alive(ref))
    IO.print(Bool.show(alive))
```

`97` is the code for `a`. Each `key` and `click` call sends both a press and a release.
`request_close` sends `Close{}` to the application. The application closes its own `Window`.
After a successful send, the application processes the events through `Window.frame`.

## Run the example

You need the [aivv73/bend fork](https://github.com/aivv73/bend) with `WindowRef`, `Window.export_ref`, and `Window.capture`.
You also need Bun, Clang, and the libX11 headers. Native window support requires Linux with X11 or Xwayland.

If the fork checkout is in the sibling directory `../bend`, the commands work without additional configuration.
For another location, set `BEND_ROOT`.

```bash
export BEND_ROOT=/absolute/path/to/bend
mkdir -p .build
./scripts/bend examples/smoke.bend -o .build/smoke
./.build/smoke
```

The example opens a window, sends events, and closes it. The expected output is `UITest smoke: OK`.
If the fork is already installed as a `bend` executable, set `BEND_BIN=/absolute/path/to/bend`.
A standard Bend installation without `WindowRef` cannot run this library.

## Test the library

```bash
./scripts/test
```

If Xvfb is available, the script creates a separate virtual display.
Otherwise, it uses `DISPLAY`. You can set the Xvfb executable path through `XVFB_BIN`.
To run checks without windows, use `./scripts/test --no-window`.

The full run checks three laws with `--verdict`, runs JavaScript in Bun and Node, builds each operation separately, and observes real events in two windows.
The key test enumerates every code in the current keyboard layout using the fork's actual decoder.
The tests also cover `Window.capture`, click boundaries, cooperative closing, and stale references.
To check memory safety, run `SANITIZE=1 ./scripts/test`. This mode enables AddressSanitizer and UndefinedBehaviorSanitizer.

See the [API reference](docs/api.md) for types, error codes, and limitations.
See the [design documentation](docs/design.md) for implementation choices and the proof boundary.
