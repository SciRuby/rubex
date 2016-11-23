module Rubex
  RUBEX_PREFIX = "__rubex_"

  FUNC_PREFIX = RUBEX_PREFIX + "f_"
  VAR_PREFIX  = RUBEX_PREFIX + "v_"
  ARGS_PREFIX = RUBEX_PREFIX + "args_"

  TYPE_MAPPINGS = {
    'i32' => 'int32_t'
  }

  CLASS_MAPPINGS = {
    'Object' => 'rb_cObject'
  }
end