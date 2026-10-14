import Base
import 0x8cc463a65f479c5af6b3080035eb0836/winref.bend as WinRef

def codes(display: String, id: U32) -> IO(List<U32>):
  import "./reference.c"
  import "./reference.js"

def key_codes(ref: WinRef.WindowRef) -> IO(List<U32>):
  WinRef.X11WindowRef{display, id} = ref
  codes(display, id)

def arrange(display: String, first: U32, second: U32) -> IO(Unit):
  import "./reference.c"
  import "./reference.js"

def separate(a: WinRef.WindowRef, b: WinRef.WindowRef) -> IO(Unit):
  WinRef.X11WindowRef{display, first} = a
  WinRef.X11WindowRef{other_display, second} = b
  arrange(display, first, second)

def snapshot(display: String) -> IO(String):
  import "./reference.c"
  import "./reference.js"

def input_state(ref: WinRef.WindowRef) -> IO(String):
  WinRef.X11WindowRef{display, id} = ref
  snapshot(display)
