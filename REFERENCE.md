# Rubex (RUBy EXtension Language)

Rubex is a language designed to keep you happy even when writing C extension.

Read on for the full specifications of the Rubex language.

# Table of Contents
<!-- MarkdownTOC autolink="true" bracket="round" depth="3"-->

- [Comments](#comments)
- [C data types](#c-data-types)
  - [Primitive data types](#primitive-data-types)
  - [C struct, union and enum](#c-struct-union-and-enum)
    - [Forward declarations](#forward-declarations)
  - [Pointers](#pointers)
- [Ruby Objects](#ruby-objects)
- [Literals](#literals)
  - [Integer](#integer)
  - [Float](#float)
  - [Character](#character)
  - [String](#string)
  - [Ruby Literals](#ruby-literals)
    - [Ruby Array](#ruby-array)
    - [Ruby Hash](#ruby-hash)
    - [Ruby String](#ruby-string)
- [C Functions and Ruby Methods](#c-functions-and-ruby-methods)
- [The print statement](#the-print-statement)
- [Loops](#loops)
  - [The while loop](#the-while-loop)
  - [The for loop](#the-for-loop)
- [Conditionals](#conditionals)
  - [Important Note](#important-note)
- [Interfacing C libraries with lib](#interfacing-c-libraries-with-lib)
  - [Basic Usage](#basic-usage)
  - [Supported declarations](#supported-declarations)
    - [Functions](#functions)
    - [Variables](#variables)
    - [Macros](#macros)
    - [Types](#types)
    - [Typedefs](#typedefs)
  - [Linking Libraries](#linking-libraries)
  - [Ready-to-use C functions](#ready-to-use-c-functions)
    - [Filename: "rubex/ruby"](#filename-rubexruby)
    - [Filename: "rubex/ruby/encoding"](#filename-rubexrubyencoding)
    - [Filename: "rubex/stdlib"](#filename-rubexstdlib)
- [Exception Handling](#exception-handling)
- ['Attach' Classes](#attach-classes)
  - [The attach keyword](#the-attach-keyword)
  - [The data$ variable](#the-data-variable)
  - [Special C functions in attach classes](#special-c-functions-in-attach-classes)
    - [deallocate](#deallocate)
    - [allocate](#allocate)
    - [memcount](#memcount)
    - [get_struct](#getstruct)
- [Typecast](#typecast)
- [Alias](#alias)
- [Conversions between Ruby and C data](#conversions-between-ruby-and-c-data)
- [C callbacks](#c-callbacks)
- [Inline C](#inline-c)
- [Differences from C](#differences-from-c)

<!-- /MarkdownTOC -->

# Comments

Similar to Ruby, comments start with `#`.

Example:
```
# This is a comment.
def funky(int j) # ...so is this.
  return j
end
```

# C data types

## Primitive data types

Following are the Rubex keywords for data types and their corresponding C types and description.

|rubex keyword         | C type         | Description  |
|:---                  |:---            |:---          |
|char                  |char            |Character              |
|i8                    |int8_t          |8 bit integer |
|i16                   |int16_t         |16 bit integer              |
|i32                   |int32_t         |32 bit integer              |
|i64                   |int64_t         |64 bit integer              |
|u8                    |uint8_t         |8 bit  unsigned integer               |
|u16                   |uint16_t        |16 bit unsigned integer              |
|u32                   |uint32_t        |32 bit unsigned integer              |
|u64                   |uint64_t        |64 bit unsigned integer              |
|int                   |int             | Integer >= 16 bits. |
|unsigned int          |unsigned int    | Unsigned integer >= 16 bits. |
|long int              |long int        | Integer >= 32 bits.|
|unsigned long int     |unsigned long int|Unsigned Integer >= 32 bits. |
|long long int         |long long int    |Integer >= 64 bits.|
|unsigned long long int|unsigned long long int|Unsigned Integer >= 64 bits.|
|f32/float             |float            |32 bit floating point              |
|f64/double            |double           |64 bit floating point              |
|long f64/long double  |long double      |Long double >= 96 bits. |
|object                |VALUE            |Ruby object |

## C struct, union and enum

C structs can defined using the `struct` keyword. For example:
``` ruby
struct node
  int a
end

def foo
  node a
  a.a = 3

  return a.a
end
```

Structs can either be at the global, class or method scope. Their accessibility will differ according to the scope they are defined in. Take note that once you define a `struct node`, the only way to define a variable of type `struct node` is just use `node` for the variable definition, not `struct node`. So `node a` will work but `struct node a` will not work.

### Forward declarations

In case your struct has a member of a type whose definition has to be after your struct, you can use a forward declaration with the `fwd` keyword.
``` ruby
fwd struct other_node
struct node
  i32 a, b
  other_node *hello
end

struct other_node
  i64 a, b
end
```

## Pointers

You can define pointers and pass them to functions just like you do in C. Pointers can be specified using the `*` operator and addresses of variables can be accessed using the `&` (address-of) operator.

Keep in mind that Rubex does not support the `*` operator for dereferencing a pointer. You will need to use the `[]` operator and access the value of pointer with `[0]` (since accessing the value of a pointer is analogous to accessing the value of an array in C).

For example:
``` ruby
class CPointersDemo
  def foo
    int *i
    int *j

    i[0] = 5
    j = i

    return j[0] 
  end
end
```

# Ruby Objects

Any variable of type `object` is a Ruby object. You must take care to not manually free objects as it will inevitably lead to memory leaks. Let the GC take care of them.

Variables that are assigned values without actually specifying the data type are also assumed to be objects.

For example:
``` ruby
def ruby_obj_demo
  object a = "string!"
  b = "string!"

  return a == b
end
```

Above function will return `true`.

# Literals

Literals in Rubex can either be represented as C data or Ruby objects depending on the type of the variable that they are assigned to. Therefore, something like `a = 1` will cause 

## Integer

## Float

## Character

## String

## Ruby Literals

### Ruby Array

### Ruby Hash

### Ruby String

# C Functions and Ruby Methods

Apart from Ruby class methods and instance methods, Rubex allows you to define 'C functions' that are only accessible inside classes from within Rubex. These functions cannot be accessed from an external Ruby script.

C functions are defined used the `cfunc` keyword. You also need to specify the return type of the function along with its definition. For example:
``` ruby
class CFunctionTest
  def foo(int n)
    return bar(n)
  end

  cfunc int bar(int n)
    return n + 5
  end
end
```

C functions are 'lexically scoped' and are available inside both Ruby instance and class methods of the class and its hierarchy.

# The print statement

The `print` statement makes it easy to print something to the console using C's `printf` function underneath. If it is passed a Ruby object instead of a C data type, the `#inspect` method will be called on the object and the resultant string will be printed. `print` can accept multiple comma-separated arguments and will concatenate them into a single string.
``` ruby
def foo(a, b)
  int i = 5

  print "Obj a is : ", a, ".", " b is: ", b, "... and i is: ", i
end
```

# Loops

Loops in Rubex are directly translated to C loops, thus giving massive gains in speed by just porting Ruby loops to Rubex. Rubex supports two kinds of loops: `while` loops and `for` loops.

## The while loop

The `while` loop in Rubex looks exactly like that in Ruby. Keep in mind that using C types for the conditional will save you the additional burden of a Ruby method call (which is takes non-trivial time for a long running loop).
``` ruby
def while_loop
  int i = 0, j

  while i < 100 do
    j += 1
    i += 1
  end

  return j
end
```

## The for loop

For loops look slightly different in Rubex than they do in Ruby. This has mainly been done to accommodate for the fact that Ruby for loops normally work with Ranges, but since that would make the code slow, Rubex `for` loops are directly translated into C `for` loops and thus follow a slightly different syntax. For example:
``` ruby
def for_loop_demo
  int i, j = 0

  for 0 <= i < 100 do
    j += 1
  end

  return j
end
```
Above code will initialize `i` to `0` and iterate through it until it does not satisfy the second conditional. The inequalities must belong to the set `{<|<=}` OR `{>|>=}`.

# Conditionals

Similar to Ruby, conditionals in Rubex can be written as follows:
``` ruby
def foo(a)
  int i = 3

  return true if a == i
  return false
end
```

In the above case, since `a` is a Ruby object and `i` is an `int`, `i` will be implicitly converted into a Ruby `Integer` and the comparison with the `==` operator will take place as though the two variables are Ruby objects (using `.send(:==)`).

## Important Note

If the expression in an `if` statements consists only of C variables, the values `0` and `NULL` (null pointer) are treated as _falsey_ and everything else is _truthy_ (exactly like C).

However, in case you intermingle Ruby and C types, Rubex will use the convention used in Ruby, i.e. `nil` (NilClass) and `false` (FalseClass) are _falsey_ whereas everything else (including zero, i.e. a Ruby `Integer` with value `0`) is _truthy_.

`0` and `NULL` will NOT be treated as _falsey_ if the expression type evaluates to a Ruby object.

# Interfacing C libraries with lib

The `lib` directive is used for interfacing external C libraries with Rubex.

## Basic Usage

Say you want to interface the `cos` and `sin` functions from the `math.h` C header file. 

It is best demonstrated by this example:
``` ruby
lib "<math.h>"
  double sin(double)
  double cos(double)
end

class CMath
  def f_sin(double n)
    return sin(n)
  end

  def f_cos(double n)
    return cos(n)
  end
end
```

The string arugument (`"<math.h>"`) supplied to `lib` is the C header file that you want to interface your code with. You first need to tell Rubex that you will be using the functions `sin` and `cos` in your program, and that they accept a `double`as an argument and also return a `double`.

These can then be directly called from the Rubex program like any other function. Keep in mind that any method/function name in your Rubex program cannot have the same names as the external C functions since they are not namespaced. This will probably be fixed in a later version.

## Supported declarations

Following statements can be used inside the `lib` directive for telling rubex about functions/variables to be used from an external C library:

### Functions

Specify the return type and arguments of the functions that you will be using in your program:
``` ruby
lib "<math.h>"
  double cos(double)
end
```

### Variables

You can specify to the Rubex compiler that you will be using constants or error values defined in C header files by specifying the name and type of the variable just like a normal variable declaration. For example:

``` ruby
lib "<ruby.h>"
  int HAVE_RUBY_DEFINES_H
end

def have_ruby_h
  return HAVE_RUBY_DEFINES_H
end
```

### Macros

Macros that work like functions, i.e. accept values and can be said to have 'return values' can be declared like any other C function:
``` ruby
lib "<ruby.h>"
  object INT2FIX(int)
end
```

### Types

If the C library uses structs or unions, you need to specify the exact name of the type and its members that you will be using so that Rubex knows what to expect from the type that you will be using. If you will not be using a certain member of the struct, there is no need to specify it. If the struct is just an argument to a function or no members are being accessed, just leave the definition empty.
``` ruby
lib "<math.h>"
  struct exception
    int type
    char *name
  end
end
```

### Typedefs

## Linking Libraries

Frequently it is necessary to link external C binaries with the compiler in order to effectively compile the C file. This is normally done by passing `-l` flags to the compiler.

Rubex allows you to do this directly inside the compiler using the `link:` option supplied to the `lib` directive. This is best demonstrated with the following example:
``` ruby
lib "csv.h", link: "csv"
  # some functions ...
end

def foo
  # some code ...
end
```

The above code will add `-lcsv` option the compiler during the compilation phase.

## Ready-to-use C functions

In order to simplify interfacing with the standard library and to call some specific functions from the Ruby C API (if you must), Rubex provides a whole bunch of ready-to-use C functions from various header files that are available by default in most systems.

For example:
``` ruby
lib "rubex/ruby"; end

def foo(a)
  return true if TYPE(a) == T_INT
  return false
end
```

Above code will use the `TYPE()` macro from the `ruby.h` header file and check if the type is `Integer`, which is denoted by the `T_INT` macro, which is another macro from `ruby.h`. Many such libraries and their enclosing functions come as default with Rubex. Here is a complete list and the also the library names that you need to pass in order to make said functions visible to your program:

### Filename: "rubex/ruby"

Functions:

|Name and prototype| Description|
|:---     |:--- |
|`void* xmalloc(void*)` | |
|`void xfree(void*)` | |
|`int TYPE(object)`||
|`object rb_str_new(char* string, long lenghth)`||
|`object rb_ary_includes(object array, object item)`||

Variables:

|Type|Name|Description|
|:---|:---|:---       |
|`int`|`T_ARRAY`||
|`int`|`T_NIL`||
|`int`|`T_TRUE`||
|`int`|`T_FALSE`||
|`int`|`T_FLOAT`||
|`int`|`T_FIXNUM`||
|`int`|`T_BIGNUM`||
|`int`|`T_REGEXP`||
|`int`|`T_STRING`||

### Filename: "rubex/ruby/encoding"

Functions:

|Name and prototype| Description|
|:---     |:--- |
|`int rb_enc_find_index(char* encoding)`||
|`object rb_enc_associate_index(object string, int encoding)`||

### Filename: "rubex/stdlib"

Functions:

|Name and prototype|Description|
|:---     |:--- |
| `int atoi(char *string)`||
| `long atol(char *string)`||
| `long long atoll(char *string)`||
| `double atof(char *string)`||

# Exception Handling

# 'Attach' Classes

## The attach keyword

## The data$ variable

## Special C functions in attach classes

### deallocate

### allocate

### memcount

### get_struct

# Typecast

You can use a C typecast using `<>`. For example:
``` ruby
def foo
  float a = 4.5
  int b = <int>a

  return b
end
```

Do not attempt typecasting between C and Ruby types. It will lead to problems. Let Rubex do that for you.

# Alias

The `alias` keyword can be used for aliasing data types. It is akin to `typedef` in C. Once the alias is declared, you can use it in your program just like any other data type.

``` ruby
def foo
  struct node
    int a, b
  end

  alias node_69 = node

  node_69 n
  n.a = 4

  return n.a
end
```

# Conversions between Ruby and C data

Rubex will implicitly convert most primitive C types like `char`, `int` and `float` to their equivalent Ruby types and vice versa. However, types conversions for user defined types like structs and unions are not supported.

# C callbacks

Frequently, C libraries use C function pointers to pass functions to other functions as callbacks. Rubex supports this behaviour too.

A C function pointer for a function that returns an `int` and accepts two `int`s as arguments can be declared as:
```
int (*foo)(int, int)
```

You can also alias function pointers with `alias`:
```
alias foo = int (*)(int, int)
```

A sample program using C function pointers is demonstrated below:
``` ruby
cfunc int foo1(int a)
  return a + 1
end

cfunc int baz1(int a, int b)
  return a + b + 1
end

cfunc int bar(int (*func1)(int), int (*func2)(int, int), int a, int b)
  return func1(a) + func2(a, b)
end

def foo
  alias goswim = int (*ernub)(int, int)
  int (*func_ptr1)(int)
  goswim func_ptr2
  int a = 1
  int b = 1

  func_ptr1 = foo1
  func_ptr2 = baz1

  return bar(func_ptr1, func_ptr2, a, b)
end
```

# Inline C

# Differences from C

* Rubex does not have dereferencing operator (`*`). Instead use `[0]` to access values pointed to by pointers.
* There is no `->` operator for accessing struct elements from a pointer to a struct. Use the `.` operator directly.

