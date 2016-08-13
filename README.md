# rubex
rubex - A Crystal-inspired language for writing Ruby extensions.

# Background

Rubex aims to make writing C extensions as intuitive as writing Ruby code. A very simple example would be a recursive implementation of a function that computes the factorial of a given number. The method for this is called `factorial` and the class in which it resides is called `Fact`. The code in rubex would like this:
``` ruby
class Fact
  def factorial(i64 n)
    return (n > 1 ? n*factorial(n-1) : 1)
  end
end
```

The rubex compiler will compile this code into the equivalent C code, and also make the appropriate calls to the CRuby C API which will perform interconversions between Ruby and C data types and register the class and it's instance method with the interpreter using the appropriate calls to `rb_define_class()` and `rb_define_method()`.

Making C extensions in this manner will GREATLY simply the process, and allow for more succint and readable extensions that look very similar to Ruby. To actually see exactly how simple writing extensions will become, the current way of writing the same `factorial` function in the `Fact` class would look something like this with pure C code:
``` c
#include <ruby.h>

int
calc_factorial(int n)
{
  return (n > 1 ? n*calc_factorial(n-1) : 1);
}

static VALUE
cfactorial(VALUE self, VALUE n)
{
  return INT2NUM(calc_factorial(NUM2INT(n)));
}

void Init_factorial()
{
  VALUE cFact = rb_define_class("Fact", rb_cObject);
  rb_define_method(cFact, "factorial", cfactorial, 1);
}
```

Now imagine growing this to solving a non-trivial problem, and the benefits imparted by rubex in terms of productivity and simplicity become increasingly apparent. Users will simply need to call a command or rake task that will generate the relevant C code and create a shared object binary, that can be then imported into any Ruby program with a call to `require`.

# Syntax specification

WARNING: Specification set to change!

#### File extensions

Rubex files will have an `.xrb` file extension.

#### Comments

Rubex will only support single line comments in lines that start with a `#` character, just like Ruby.

#### Line termination

A line of code can be terminated with a newline (`\n`) character.

#### Support for C data types

The above example demonstrated the factorial function being used with a 64 bit integer data type, and rubex will support many such data types. The keywords for these data types will be borrowed from Crystal, and they will be translated to the corresponding C types with the rubex compiler. For the first version (v0.1) the following data types will be supported:

|rubex keyword         | C type | Description  |
|:---                  |:---    |:---          |
|char                  |char        |Character              |
|i8                    |int8_t        |8 bit integer |
|i16                   |int16_t        |16 bit integer              |
|i32                   |int32_t        |32 bit integer              |
|i64                   |int64_t        |64 bit integer              |
|u8                    |uint8_t        |8 bit  unsigned integer               |
|u16                   |uint16_t        |16 bit unsigned integer              |
|u32                   |uint32_t        |32 bit unsigned integer              |
|u64                   |uint64_t        |64 bit unsigned integer              |
|int                   |int  | Integer >= 16 bits. |
|unsigned int          |unsigned int| Unsigned integer >= 16 bits. |
|long int              |long int| Integer >= 32 bits.|
|unsigned long int     |unsigned long int|Unsigned Integer >= 32 bits. |
|long long int         |long long int|Integer >= 64 bits.|
|unsigned long long int|unsigned long long int|Unsigned Integer >= 64 bits.|
|f32/float             |float        |32 bit floating point              |
|f64/double            |double        |64 bit floating point              |
|long f64/long double  |long double|Long double >= 96 bits. |
|object                |VALUE        |Ruby object |

Variables with these data types can be declared by writing the data type keyword before the variable name, and will not follow the Crystal convention. So for example, to declare some integers and floats in rubex, you would do this:
```
i32 int_number
f64 float_number
i8 u, i = 33
```
I will use the `stdint.h` header file that provides support for declaring integer types of precise bit length.

#### Structs

You can define your own C structures using the `struct` keyword. It can contain any sort of data type inside it, just like structs in C. It can also contain references and pointers to itself. To create a struct called 'Node', you can use the following syntax:
```
struct Node do
  int data
  struct Node* next
end
# C equivalent:
# struct Node {
#   int data;
#   struct Node* next;    
# };
```
Varibles of type `Node` can be declared by using `struct Node`, like `struct Node foo`, or pointers with `Pointer(struct Node)` or `struct Node*`.

#### Typedefs

The `struct` in the example above can also be aliased with the `alias` keyword. The function of `alias` is similar to `typedef` in C. So `alias Node = struct Node` will declarations in the form of `Node foo`. Once a type has been aliased, the original name (`struct Node`) can be used interchangably with the new name (`Node`).

#### Unions

A C union can be defined with the `union` keyword similar to the way a `struct` is declared. For example,
```
union IntAndFloat do
  i32 a
  f32 b
end
```

The `union` must either be aliased to some other user-defined type or must be reffered to by the `union` keyword. So a variable of the above union will be declared as `union IntAndFloat intfloat`.

#### Enums

A C `enum` can be declared with the `enum` keyword. Each element in the enum will be separated by newlines (`\n`) or commas (`,`), and default values starting from `0` will be assigned to successive enum elements. For example,
```
enum Week do
  monday
  tuesday
  wednesday
  thursday
  friday
  saturday
  sunday
end
```

The default values can be changed with an assignment:
```
enum SomeEnum do
  one = 3,
  two = 5,
end
```

#### Functions

There can basically be two types of functions that will need to be defined in rubex:

* _Pure Ruby methods_ that take a Ruby object as the first argument (the `VALUE` in C extensions, see the `cfactorial` method in the above example) and return a Ruby object.
* _C methods_ that purely take C data types as input and return a C data type (for example the `calc_factorial` function in the above example).

These two kinds of methods will have slightly different syntax when it comes to defining methods. Let me elaborate on them both:

**Pure Ruby Methods**

These will be defined just like normal Ruby methods, but will support typed formal parameters. Internally they will be translated to functions that accept `VALUE` as the first argument and return `VALUE`.

To define a method of this kind, the user can use syntax that looks like this:
``` ruby
def plus_one(f32 n)
  n + 1
end
```

When a parameter of a Ruby method is declared to have a C type, it passed a Ruby object, which is then converted to a C value if possible. If the data type is not speicified, the function will take a Ruby object as an argument.

ONLY THESE METHODS WILL BE CALLABLE FROM INTERPRETED RUBY CODE. 

**Pure C Methods**

These are methods that are only callable from C code. They cannot be called directly from interpreted Ruby code.

They also look very similar to the pure Ruby methods, but have a caveat that they must be defined with `cdef` instead of `def` and should also specify a return data type. These methods must specify the type of their formal arguments. Therefore, the syntax for writing a simple addition function would look like this:
``` ruby
cdef f32 plus_one(f32 n)
  n + 1
end
```
In above example, the function `plus_one` takes a 32 bit floating point number `n` as an argument and returns a 32 bit floating point number after adding `1` to it. If a return type is not specified for a C function, it is assumed to be `VALUE` (Ruby object).

These functions will also be compiled such that the last line is actually the return statement, as is the case in Ruby. Pure C methods will only be callable from rubex and cannot be called by external interpreted Ruby code.

**Passing functions to other functions**

C functions (i.e. those defined with the `cdef` keyword) can be passed to other functions, just like C function pointers. If a C method accepts a function of a particular type signature it can be specified with the `Function()` keyword. The last argument to the `Function()` keyword is the return type of that function. The functionality can also be realized by specifying the function as `input parameters type -> return type`.

For example, a function that accepts two arguments, one of type `i32` and the other of type `f64` and returns a varible of type `i32` can be specified by either `Function(i32,f64,i32)` or `i32, f64 -> i32`.

#### Variables

Any variable can have the `extern` or `static` keyword associated with it in order to declare it so.

#### Pointers

Rubex will allow declaring pointers with either the `*` operator or the `Pointer()` keyword. For example, an `i32` pointer can be declared as either `*i32` or `Pointer(i32)`. Notice that the 'P' of `Pointer()` is in capitals. This notation will be followed for all compiler directives that take arguments.

#### Literals

Several literals will be available for creating many basic types in the language. I have listed some of the major ones below:

* **nil** - This (`nil`) represent's Ruby's NilClass object, and will be translated to the `Qnil` Ruby constant according to the C API.
* **Boolean values** - `true` and `false` are the literals for boolean values and will be translated to `Qtrue` and `Qfalse` by the compiler.
* **Integers** - Rubex will not make any assumptions about variables without an associated type assigned to integers. Thus, in order to create C integers, users must specify the data type of the variable. Therefore, `i = 3` will lead to `i` being compiled as a Ruby `Fixnum` object, and `i32 i = 3` will compile to a C 32 bit integer as `int32_t i = 3`.
* **Floats** - The assumptions made for integers will apply to floats as well.
* **Character** - Character `char` literals can be specified by enclosing the character in single quotes (`'` and `'`). These are equivalent to character literals in C.
* **Strings** - String literals are enclosed inside double quotes (`"` and `"`). When assigning a string literal to a variable, the variable must be of type `char*`. If the type is not specified, it will be treated as a Ruby string.
* **Symbol** - Rubex symbols use the exact same syntax as Ruby symbols, and will be directly translated to the relevant C API function for creating symbols.

#### Arrays

C arrays of a definite size (static arrays) can be specified using square brackets after the variable name. For example, to declare an array of 10, 16-bit integers, the syntax would be `i16 arr[10]`. Static arrays can also be declared with the `StaticArray()` keyword. Thus, to declare a C static array of `i8` of size `8`, you can either use`StaticArray(i8, 8)` or `i8[8]`.

If a Ruby array is specified using Ruby's Array literal syntax (`[]`), it will be directly translated into a Ruby Array object. For example the statement `a = []` will store a Ruby Array object in the variable 'a'.

#### Loops

Rubex will itself define a `for` loop for performing integer iterations. The syntax for this will be as follows:
```
i32 i, s = 0, m = 10
for s < i <= m do
  # code
end
```

If the loop variable `i` and lower and upper bounds are all C integer expressions, this loop will be directly compiled into a C for-loop and will be very fast. The direction of the iteration is determined by the relations. If they are from the `{<,<=}` the iteration is upwards, or if they are from the set `{>,>=}`, the iteration is downwards.

#### Wrapping C functions

This is the most important functionality of rubex. A lot of it will be borrowed from Crystal since Crystal's API for creating C bindings is very well thought out and simple.

**lib**

For interfacing any C library with Ruby, rubex will provide the `lib` keyword. The `lib` declaration will basically group C functions and types that belong to a particular library. For example,
```
#@[Link("pcre")]
lib LibPCRE
end
```

The syntax above the `lib` declaration is a special 'magic comments' syntax. The presence of `@[...]` after the `#` of the comments will allow the Rubex compiler to know that the comment is not a regular comment but is actually a directive for an operation that is to be performed by the compiler. 

The `Link` keyword inside the `@[...]` syntax of the magic comment will ensure that appropriate flags are passed to the compiler to find the external libraries. So for example, it the above case, the `Link("pcre")` directive will `-lpcre` to the linker.

If `Link(ldflags: "...")` is passed into the magic comment, those flags will be passed directly to the linker, without any modification, for example `Link(ldflags: "-lpcre")`. Enclosing those commands inside backticks will execute those commands, for example `Link(ldflags: "`pkg-config libpcre --libs`")`.

**require_header**

The `require_header` keyword will include C headers in the generated C code. For example `require_header 'math'` will put a statement `#include <math.h>`.

**fun**

A `fun` declaration will bind a C function.
```
require_header 'math'

class Maths
  def cos(f32 v)
    CMath.cos(v)
  end
end

lib CMath
  fun f32 cos(f32 value)
end
```
The user can the call the `cos` function from Ruby with `Maths.new.cos(0.7)`. Calls to `fun` must be inside a `lib` block. This facilitates easy linking and namespacing of C bindings.

The parentheses can be omitted if the function does not accept arguments:
```
# In rubex
lib C
  fun i32 getch
end

# In Ruby
C.getch
```
If the return type is `void` you can omit it:
```
# In Rubex
lib C
  fun srand(u32 seed)
end

# In Ruby
C.srand(1)
```

Functions with variable arguments can also be bound:
```
# In Rubex
lib X
  fun i32 variadic(i32 value, ...)
end

# In Ruby
X.variadic(1, 2, 3, 4)
```

If a function starts with a name that you don't want to use in your Ruby program, or if it contains characters that cannot be used in Ruby methods, you can assign it a different name with `=`. For example,
```
lib C
  fun cosine = f32 cos(f32 value)
end
```
Or say the function starts with a capital letter (which is a constant in Ruby and is confusing to use as a method name) or contains an invalid character like `.`, in which case you can wrap it in a string:
```
lib LibSDL
  fun init = u32 SDL_Init(u32 flags)
end

lib LLVMIntrinsics
  fun ceil_f32 = f32 "llvm.ceil.f32"(f32 value) 
end
```

#### Embedding C code

If you must write C, you can do that with a `%{ ... %}` block or a `BEGIN_C do ... end` block.
