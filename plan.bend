import Base

def key(+code: U32) -> List<Event>:
  [Key{code, True{}}, Key{code, False{}}]

def click(+x: U32, +y: U32) -> List<Event>:
  +px = U32.to_f32(x)
  +py = U32.to_f32(y)
  [Press{0, Tool.Mouse{}, px, py, 0, 0, True{}},
   Press{0, Tool.Mouse{}, px, py, 0, 0, False{}}]

def request_close() -> List<Event>:
  [Close{}]
