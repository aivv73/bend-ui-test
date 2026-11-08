import Base
import ./plan.bend as Plan

law key_pair:
  for +code: U32
  {Plan.key(code) == [Key{code, True{}}, Key{code, False{}}] : List<Event>}

law click_pair:
  for +x: U32
  for +y: U32
  {Plan.click(x, y) ==
    [Press{0, Tool.Mouse{}, U32.to_f32(x), U32.to_f32(y), 0, 0, True{}},
     Press{0, Tool.Mouse{}, U32.to_f32(x), U32.to_f32(y), 0, 0, False{}}] : List<Event>}

law close_one:
  {Plan.request_close() == [Close{}] : List<Event>}
