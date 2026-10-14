# UITest design

`plan.bend` builds complete `Event` sequences.
`uitest.bend` combines these plans with `WinRef.WindowRef` from the pinned Hub package.
It unpacks the reference in Bend and passes its display name and window ID to the native backend once per operation.
The native tests obtain references through `WinRef.WinRef.export` and read pixels through the Hub capture package's `Capture.Window.capture`.
`uitest.c` validates the plan, opens the specified display, and sends events through `XSendEvent`.
`uitest.js` returns ENOTSUP.

One IO handler sends both the press and release before the next Bend effect.
Sequential `do IO` calls preserve request order.
Another X11 client or window destruction can still intervene between the two requests.

## Implementation choices

Three independent designs and a separate review used the same model.
The selected design uses a native backend that targets a specific window and consumes a pure event plan.

| Option | Decision |
|---|---|
| Native XSendEvent with a `List<Event>` plan | Selected. Hides X11 details behind four calls and requires no separate executable. |
| A separate helper through `Process.run` | Rejected for the current scope. It isolates fatal Xlib errors but requires helper installation and a new process for each call. |
| A pure KeySym table and native plan | Contributed the namespace rules and separate builds for each operation. The static table was replaced by lookup through the actual layout decoder. |
| XTest | Rejected. Events depend on the global cursor and focus, and it requires libXtst. |

The shared C effects are declared in one Bend module.
`CID(X11WindowRef)` is unavailable in the UITest native module because the constructor belongs to the Hub package.
The native ABI therefore uses Base event constructors and primitive reference fields.

Model the Domain established `List<Event>` as a complete operation plan.
Boundary Discipline concentrated reference, geometry, and X11 error checks at the C effect boundary.
Separate Before Serializing Shared State assigned one implementation owner and separate files for the alternative designs.
Build the Lever led to the reproducible `scripts/test` runner.
Prove It Works requires comparing actual `Window.frame` events with expected values.

## Proof boundary

`LAWS.bend` imports only Base and `plan.bend`.
Three laws specify the exact event lists for a key press, left click, and close request.
`PROOF.bend` proves them without `@unsafe` or foreign definitions.

The proofs cover order, key codes, coordinates, and button identity in the plan.
They do not prove Xlib behavior, event delivery, window lifetime, or C ABI correctness.
Native tests check those properties. The layout test obtains codes through the actual `window_key` in the upstream compiler.
If the upstream decoder changes, the test compares its behavior with the library.

## Verification

`scripts/test` runs the standard PROOF check and `--verdict` with the proven kernel.
It then runs JavaScript in Bun and Node, builds each public operation separately, and runs the native tests.
Native tests check event sequences, all layout codes, two separate windows, frame readback, and stale-reference errors.
On Linux, an additional build with `-U__linux__` exercises the branch without X11.
`SANITIZE=1` adds AddressSanitizer and UndefinedBehaviorSanitizer to the native test.

The [API reference](api.md) lists the Xlib and `WindowRef` limitations.
