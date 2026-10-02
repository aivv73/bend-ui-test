import Base
import ./plan.bend as Plan

def send(ref: WindowRef, events: List<Event>) ->
  IO(Result<&1, &1, U32 & String, Unit>):
  import "./uitest.c"
  import "./uitest.js"

def key(ref: WindowRef, code: U32) ->
  IO(Result<&1, &1, U32 & String, Unit>):
  send(ref, Plan.key(code))

def click(ref: WindowRef, x: U32, y: U32) ->
  IO(Result<&1, &1, U32 & String, Unit>):
  send(ref, Plan.click(x, y))

def request_close(ref: WindowRef) ->
  IO(Result<&1, &1, U32 & String, Unit>):
  send(ref, Plan.request_close())

def alive(ref: WindowRef) -> IO(Result<&1, &1, U32 & String, Bool>):
  import "./uitest.c"
  import "./uitest.js"
