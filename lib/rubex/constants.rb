module Rubex
  RUBEX_PREFIX = "__rubex_"

  RUBY_FUNC_PREFIX = RUBEX_PREFIX + "rb_f_"
  C_FUNC_PREFIX = RUBEX_PREFIX + "c_f_"
  VAR_PREFIX  = RUBEX_PREFIX + "v_"
  RUBY_CLASS_PREFIX = RUBEX_PREFIX + "rb_cls_"
  ARG_PREFIX = RUBEX_PREFIX + "arg_"
  ARRAY_PREFIX = RUBEX_PREFIX + "arr_"
  POINTER_PREFIX = RUBEX_PREFIX + "ptr_"
  TYPE_PREFIX   = RUBEX_PREFIX + "t_"

  ACTUAL_ARGS_SUFFIX = "_actual_args"

  TYPE_MAPPINGS = {
    'char'                   => Rubex::DataType::Char,
    'i8'                     => Rubex::DataType::Int8,
    'i16'                    => Rubex::DataType::Int16,
    'i32'                    => Rubex::DataType::Int32,
    'i64'                    => Rubex::DataType::Int64,
    'u8'                     => Rubex::DataType::UInt8,
    'u16'                    => Rubex::DataType::UInt16,
    'u32'                    => Rubex::DataType::UInt32,
    'u64'                    => Rubex::DataType::UInt64,
    'int'                    => Rubex::DataType::Int,
    'unsigned int'           => Rubex::DataType::UInt,
    'long int'               => Rubex::DataType::LInt,
    'unsigned long int'      => Rubex::DataType::ULInt,
    'long long int'          => Rubex::DataType::LLInt,
    'unsigned long long int' => Rubex::DataType::ULLInt,
    'f32'                    => Rubex::DataType::F32,
    'float'                  => Rubex::DataType::F32,
    'f64'                    => Rubex::DataType::F64,
    'double'                 => Rubex::DataType::F64,
    'object'                 => Rubex::DataType::RubyObject
  }

  CUSTOM_TYPES = {}

  DEFAULT_CLASS_MAPPINGS = {
    'Object' => 'rb_cObject'
  }

  # Maps regexes to the type of the variable for conversion from literal
  # to the correct type of Ruby object.
  LITERAL_MAPPINGS = {
    /'.\'/       => Rubex::DataType::Char,
    /-?\d+/      => Rubex::DataType::Int,
    /-?\d+\.\d+/ => Rubex::DataType::F64
  }
end
