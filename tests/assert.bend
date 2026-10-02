import Base

def check(ok: Bool, message: String) -> IO(Unit):
  match ok:
    case True{}:
      IO.pure(Unit, Unit{})
    case False{}:
      IO.die(Unit, 1, "FAIL: " ++ message)

def error_unit(expected: U32, result: Result<&1, &1, U32 & String, Unit>) -> Bool:
  match result:
    case Fail{(code, text)}:
      U32.is_eq(code, expected)
    case Done{unit}:
      False{}

def error_bool(expected: U32, result: Result<&1, &1, U32 & String, Bool>) -> Bool:
  match result:
    case Fail{(code, text)}:
      U32.is_eq(code, expected)
    case Done{value}:
      False{}

def success_bool(expected: Bool, result: Result<&1, &1, U32 & String, Bool>) -> Bool:
  match result:
    case Done{value}:
      U32.is_eq(Bool.to_u32(value), Bool.to_u32(expected))
    case Fail{error}:
      False{}
