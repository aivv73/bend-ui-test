# Bend UI test

This library sends key presses, clicks, and close requests to an upstream Bend window using a copyable reference.
Obtain the reference through `WinRef.WinRef.export`. The application retains ownership of `Window`.

The dependencies are pinned to these BendHub packages:

- [Window references 0.1.0.1](https://hub.bend-lang.com/0x3d4f2512cce00e5099d03d9e1b3b9ae1) provide `WindowRef` and `WinRef.export`.
- [Window capture 0.1.0.1](https://hub.bend-lang.com/0x493e83fed22415cb35e84da752fefdef) provides `Capture` and `Window.capture` for native tests, using Bend 2.0.39's array runtime.

```python
import Base
import 0x3d4f2512cce00e5099d03d9e1b3b9ae1/winref.bend as WinRef
import ./uitest.bend as UITest

def drive(+ref: WinRef.WindowRef) -> IO(Unit):
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

Use upstream [Bend](https://bend-lang.com), tested with version 2.0.39.
Update an existing installation with `bend update`.
You also need Clang and the libX11 headers. Native window support requires Linux with X11 or Xwayland.
Bend downloads and verifies the pinned Hub imports on the first build.

```bash
bend update
mkdir -p .build
./scripts/bend examples/smoke.bend -o .build/smoke
./.build/smoke
```

The example opens a window, sends events, and closes it. The expected output is `UITest smoke: OK`.
`scripts/bend` uses the installed `bend` executable. Set `BEND_BIN` to select another executable.

## Test the library

```bash
./scripts/test
```

If Xvfb is available, the script creates a separate virtual display.
Otherwise, it uses `DISPLAY`. You can set the Xvfb executable path through `XVFB_BIN`.
To run checks without windows, use `./scripts/test --no-window`.

The full run requires Bun and Node. It checks three laws with `--verdict`, runs JavaScript in Bun and Node, builds each operation separately, and observes real events in two windows.
The key test enumerates every code in the current keyboard layout using the upstream compiler's actual decoder.
The tests also cover `Capture.Window.capture`, click boundaries, cooperative closing, and stale references.
To check memory safety, run `SANITIZE=1 ./scripts/test`. This mode enables AddressSanitizer and UndefinedBehaviorSanitizer.
On Bend 2.0.39, LeakSanitizer reports an upstream startup allocation; see the [verification notes](docs/design.md#verification) for the reproduction and workaround.

See the [API reference](docs/api.md) for types, error codes, and limitations.
See the [design documentation](docs/design.md) for implementation choices and the proof boundary.
