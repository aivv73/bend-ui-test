# UITest API

The module is imported as `import ./uitest.bend as UITest`.
`Event` is defined in upstream Bend's Base library.
`WindowRef` is defined in the pinned [window-reference package](https://hub.bend-lang.com/0x8cc463a65f479c5af6b3080035eb0836).

```python
import 0x8cc463a65f479c5af6b3080035eb0836/winref.bend as WinRef
```

References have type `WinRef.WindowRef` and constructor `WinRef.X11WindowRef{display, id}`.
`WinRef.WinRef.export(window)` returns `IO(Window & Result<&1, &1, U32 & String, WinRef.WindowRef>)`.
The affine owner returns outside `Result` on success and failure.

| Call | Result | Behavior |
|---|---|---|
| `UITest.key(ref, code)` | `IO(Result<&1, &1, U32 & String, Unit>)` | Presses and releases a key. `code` is a `U32` matching an `Event.Key` code. |
| `UITest.click(ref, x, y)` | `IO(Result<&1, &1, U32 & String, Unit>)` | Presses and releases the left mouse button at client-area pixel coordinates. `x` and `y` are `U32` values. |
| `UITest.request_close(ref)` | `IO(Result<&1, &1, U32 & String, Unit>)` | Sends `WM_DELETE_WINDOW` to the application, which Bend receives as `Close{}`. |
| `UITest.alive(ref)` | `IO(Result<&1, &1, U32 & String, Bool>)` | Returns `Done{True{}}` for an existing window and `Done{False{}}` for a window that no longer exists. |

`Done{Unit{}}` means that the X11 server accepted the send.
It does not acknowledge application processing.
Sequential calls in `do IO` preserve the order of actions on one window.
Independent computations have no shared ordering guarantee.

## Key codes

| Key | Bend code |
|---|---|
| `a`, `!`, Space | `97`, `33`, `32` |
| Tab, Enter, Escape, Backspace | `9`, `13`, `27`, `127` |
| Up, Down, Left, Right | `63232`, `63233`, `63234`, `63235` |
| F1 ... F12 | `63236` ... `63247` |
| Insert, Delete, Home, End | `63271`, `63272`, `63273`, `63275` |
| Page Up, Page Down | `63276`, `63277` |
| Left Shift, Right Shift | `65592`, `65596` |
| Left Control, Right Control | `65595`, `65598` |

The code is not an X11 KeySym or a physical keycode.
The backend selects a keycode and Shift and Lock state for the current layout so that Bend's decoder returns the requested code.
Fallback codes of the form `65536 + keycode` also require an exact match with the decoder's output.

Bend converts uppercase Latin letters to lowercase. For example, `65` is rejected, while `97` represents `a`.
This is a keyboard event API. It does not enter arbitrary Unicode text or retain modifier state between calls.

## Coordinates and ownership

The coordinate origin is the top-left corner of the window's content.
Window decorations and desktop position are excluded.
Valid coordinates satisfy `x < width`, `y < height`, `x <= 32767`, and `y <= 32767`.
Bend uses button number `0` for the left mouse button.

The library opens a temporary connection to the display named in the reference.
It does not move the cursor or change focus or global key state.
The application retains `Window`. `request_close` does not destroy the window.
The reference expires with its window owner.

## Errors

Errors are represented as `Fail{(errno, message)}`.

| Linux code | Cause |
|---|---|
| `2`, ENOENT | The display is unavailable or the window disappeared before the send. For a window that no longer exists, `alive` returns `Done{False{}}`. |
| `22`, EINVAL | An empty display name, embedded NUL, zero window ID, invalid key code, or invalid coordinates. |
| `95`, ENOTSUP | The key is unavailable in the layout, the window does not accept the required events, `WM_DELETE_WINDOW` is missing, or the backend is unsupported. |
| `11`, EAGAIN | X11 reported `BadMatch`. |
| `5`, EIO | Another X11 protocol or send error. |

JavaScript always returns `Fail` with code `95` for all four operations.
The native backend outside Linux returns the platform's ENOTSUP value.

## Limitations

Native Bend windows under X11 and Xwayland are supported. Pure Wayland and JavaScript do not support event injection.
The key decoder matches upstream Bend 2.0.37's `window_key`.
Changing the keyboard layout after creating a window can make the owner's cached decoder disagree with the sender's new connection.

`alive` reports whether the window exists at the time of the query.
X11 can reuse IDs, and `WindowRef` has no resource generation identifier.
An `alive` check does not guarantee that the next call succeeds.

If the window disappears between two events, the press may already have arrived while the call returns `Fail`.
If the connection to the X11 server itself is lost, Xlib can terminate the process.
Handling stale IDs does not provide recovery from that disconnection or an XSync timeout.
