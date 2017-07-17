module Rubex
  RUBEX_PREFIX = "__rubex_"

  RUBY_FUNC_PREFIX = RUBEX_PREFIX + "rb_f_"
  C_FUNC_PREFIX = RUBEX_PREFIX + "c_f_"
  VAR_PREFIX  = RUBEX_PREFIX + "v_"
  RUBY_CLASS_PREFIX = RUBEX_PREFIX + "rb_cls_"
  ATTACH_CLASS_PREFIX = RUBEX_PREFIX + "attach_rb_cls"
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
    'object'                 => Rubex::DataType::RubyObject,
    'void'                   => Rubex::DataType::Void,
    'size_t'                 => Rubex::DataType::Size_t
  }

  CUSTOM_TYPES = {}

  DEFAULT_CLASS_MAPPINGS = {
    "Kernel" => "rb_mKernel",
    "Comparable" => "rb_mComparable",
    "Enumerable" => "rb_mEnumerable",
    "Errno" => "rb_mErrno",
    "FileTest" => "rb_mFileTest",
    "GC" => "rb_mGC",
    "Math" => "rb_mMath",
    "Process" => "rb_mProcess",
    "WaitReadable" => "rb_mWaitReadable",
    "WaitWritable" => "rb_mWaitWritable",
    "BasicObject" => "rb_cBasicObject",
    "Object" => "rb_cObject",
    "Array" => "rb_cArray",
    "Bignum" => "rb_cBignum",
    "Binding" => "rb_cBinding",
    "Class" => "rb_cClass",
    "Cont" => "rb_cCont",
    "Dir" => "rb_cDir",
    "Data" => "rb_cData",
    "FalseClass" => "rb_cFalseClass",
    "Encoding" => "rb_cEncoding",
    "Enumerator" => "rb_cEnumerator",
    "File" => "rb_cFile",
    "Fixnum" => "rb_cFixnum",
    "Float" => "rb_cFloat",
    "Hash" => "rb_cHash",
    "Integer" => "rb_cInteger",
    "IO" => "rb_cIO",
    "Match" => "rb_cMatch",
    "Method" => "rb_cMethod",
    "Module" => "rb_cModule",
    "NameErrorMesg" => "rb_cNameErrorMesg",
    "NilClass" => "rb_cNilClass",
    "Numeric" => "rb_cNumeric",
    "Proc" => "rb_cProc",
    "Random" => "rb_cRandom",
    "Range" => "rb_cRange",
    "Rational" => "rb_cRational",
    "Complex" => "rb_cComplex",
    "Regexp" => "rb_cRegexp",
    "Stat" => "rb_cStat",
    "String" => "rb_cString",
    "Struct" => "rb_cStruct",
    "Symbol" => "rb_cSymbol",
    "Thread" => "rb_cThread",
    "Time" => "rb_cTime",
    "TrueClass" => "rb_cTrueClass",
    "UnboundMethod" => "rb_cUnboundMethod",
    "Exception" => "rb_eException",
    "StandardError" => "rb_eStandardError",
    "SystemExit" => "rb_eSystemExit",
    "Interrupt" => "rb_eInterrupt",
    "Signal" => "rb_eSignal",
    "Fatal" => "rb_eFatal",
    "ArgumentError" => "rb_eArgError",
    "EOFError" => "rb_eEOFError",
    "IndexError" => "rb_eIndexError",
    "StopIteration" => "rb_eStopIteration",
    "KeyError" => "rb_eKeyError",
    "RangeError" => "rb_eRangeError",
    "IOError" => "rb_eIOError",
    "RuntimeError" => "rb_eRuntimeError",
    "SecurityError" => "rb_eSecurityError",
    "SystemCallError" => "rb_eSystemCallError",
    "ThreadError" => "rb_eThreadError",
    "TypeError" => "rb_eTypeError",
    "ZeroDivError" => "rb_eZeroDivError",
    "NotImpError" => "rb_eNotImpError",
    "NoMemError" => "rb_eNoMemError",
    "NoMethodError"    => "rb_eNoMethodError",
    "FloatDomainError" => "rb_eFloatDomainError",
    "LocalJumpError"   => "rb_eLocalJumpError",
    "SysStackError"    => "rb_eSysStackError",
    "RegexpError"      => "rb_eRegexpError",
    "EncodingError"    => "rb_eEncodingError",
    "EncCompatError"   => "rb_eEncCompatError",
    "ScriptError"      => "rb_eScriptError",
    "NameError"        => "rb_eNameError",
    "SyntaxError"      => "rb_eSyntaxError",
    "LoadError"        => "rb_eLoadError",
    "MathDomainError"  => "rb_eMathDomainError",
    "STDIN"            => "rb_stdin",
    "STDOUT"           => "rb_stdout",
    "STDERR"           => "rb_stderr",
  }

  C_MACRO_INT2BOOL = Rubex::RUBEX_PREFIX + "INT2BOOL"

  # Maps regexes to the type of the variable for conversion from literal
  # to the correct type of Ruby object.
  LITERAL_MAPPINGS = {
    /'.\'/       => Rubex::DataType::Char,
    /-?\d+/      => Rubex::DataType::Int,
    /-?\d+\.\d+/ => Rubex::DataType::F64
  }
end
