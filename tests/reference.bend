import Base

def codes(display: String, id: U32) -> IO(List<U32>):
  import "./reference.c"
  import "./reference.js"

def key_codes(ref: WindowRef) -> IO(List<U32>):
  X11WindowRef{display, id} = ref
  codes(display, id)

def arrange(display: String, first: U32, second: U32) -> IO(Unit):
  import "./reference.c"
  import "./reference.js"

def separate(a: WindowRef, b: WindowRef) -> IO(Unit):
  X11WindowRef{display, first} = a
  X11WindowRef{other_display, second} = b
  arrange(display, first, second)

def snapshot(display: String) -> IO(String):
  import "./reference.c"
  import "./reference.js"

def input_state(ref: WindowRef) -> IO(String):
  X11WindowRef{display, id} = ref
  snapshot(display)
