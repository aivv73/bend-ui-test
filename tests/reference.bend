import Base
import 0xc49b12025f945d56de002cde2237ecc5/winref.bend as WinRef

type CloseWatch is Type:
  CloseWatch{low: U32, high: U32}

def watch_close_at(display: String, id: U32) -> IO(CloseWatch):
  import "./reference.c"
  import "./reference.js"

def watch_close(ref: WinRef.WindowRef) -> IO(CloseWatch):
  WinRef.X11WindowRef{display, id} = ref
  watch_close_at(display, id)

def await_close(watch: CloseWatch) -> IO(Unit):
  import "./reference.c"
  import "./reference.js"

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
