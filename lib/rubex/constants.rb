module Rubex
  RUBEX_PREFIX = "__rubex_"

  FUNC_PREFIX = RUBEX_PREFIX + "f_"
  VAR_PREFIX  = RUBEX_PREFIX + "v_"
  CLASS_PREFIX = RUBEX_PREFIX + "c_"
  ARG_PREFIX = RUBEX_PREFIX + "arg_"

  TYPE_MAPPINGS = {
    'char'                   => Rubex::DataType::Char,
    'i8'                     => Rubex::DataType::Int8,
    'i16'                    => Rubex::DataType::Int16,
    'i32'                    => Rubex::DataType::Int32,
    'i64'                    => Rubex::DataType::Int64,
    'ui8'                    => Rubex::DataType::UInt8,
    'ui16'                   => Rubex::DataType::UInt16,
    'ui32'                   => Rubex::DataType::UInt32,
    'ui64'                   => Rubex::DataType::UInt64,
    'int'                    => Rubex::DataType::Int,
    'unsigned int'           => Rubex::DataType::UInt,
    'long int'               => Rubex::DataType::LInt,
    'unsigned long int'      => Rubex::DataType::ULInt,
    'long long int'          => Rubex::DataType::LLInt,
    'unsigned long long int' => Rubex::DataType::ULLInt,
    'float'                  => Rubex::DataType::F32,
    'double'                 => Rubex::DataType::F64,
    'object'                 => Rubex::DataType::RubyObject
  }

  CLASS_MAPPINGS = {
    'Object' => 'rb_cObject'
  }
end