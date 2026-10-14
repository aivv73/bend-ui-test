import Base
import 0x8cc463a65f479c5af6b3080035eb0836/winref.bend as WinRef
import ./plan.bend as Plan

def send_to(display: String, id: U32, events: List<Event>) ->
  IO(Result<&1, &1, U32 & String, Unit>):
  import "./uitest.c"
  import "./uitest.js"

def send(ref: WinRef.WindowRef, events: List<Event>) ->
  IO(Result<&1, &1, U32 & String, Unit>):
  WinRef.X11WindowRef{display, id} = ref
  send_to(display, id, events)

def key(ref: WinRef.WindowRef, code: U32) ->
  IO(Result<&1, &1, U32 & String, Unit>):
  send(ref, Plan.key(code))

def click(ref: WinRef.WindowRef, x: U32, y: U32) ->
  IO(Result<&1, &1, U32 & String, Unit>):
  send(ref, Plan.click(x, y))

def request_close(ref: WinRef.WindowRef) ->
  IO(Result<&1, &1, U32 & String, Unit>):
  send(ref, Plan.request_close())

def alive_at(display: String, id: U32) -> IO(Result<&1, &1, U32 & String, Bool>):
  import "./uitest.c"
  import "./uitest.js"

def alive(ref: WinRef.WindowRef) -> IO(Result<&1, &1, U32 & String, Bool>):
  WinRef.X11WindowRef{display, id} = ref
  alive_at(display, id)
