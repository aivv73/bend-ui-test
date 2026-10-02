import Base

def key(+code: U32) -> List<Event>:
  [Key{code, True{}}, Key{code, False{}}]

def click(+x: U32, +y: U32) -> List<Event>:
  [Mouse{x, y, 0, True{}}, Mouse{x, y, 0, False{}}]

def request_close() -> List<Event>:
  [Close{}]
