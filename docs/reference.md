---
layout: page
title: Reference
---

# Rubex (RUBy EXtension Language)

Rubex is a language designed to keep you happy even when writing C extension.

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
    - [Ruby Symbol](#ruby-symbol)
    - [Ruby Array](#ruby-array)
    - [Ruby Hash](#ruby-hash)
- [C Functions and Ruby Methods](#c-functions-and-ruby-methods)
- [Ruby Constants](#ruby-constants)
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
    - [gc_mark](#gcmark)
- [Typecast](#typecast)
- [Alias](#alias)
- [Conversions between Ruby and C data](#conversions-between-ruby-and-c-data)
- [C callbacks](#c-callbacks)
- [Inline C](#inline-c)
- [Handling Strings](#handling-strings)
- [Differences from C](#differences-from-c)
- [Differences from Ruby](#differences-from-ruby)
- [Limitations](#limitations)

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

In case you declare a pointer to a struct, the elements of the struct should still be accessed with `.` since the `->` operator is not supported in Rubex.
Example:
``` ruby
def foo
  struct bar
    int a
  end

  bar *n
  n.a = 3

  return n.a
end
```

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

Literals in Rubex can either be represented as C data or Ruby objects depending on the type of the variable that they are assigned to. Therefore, something like `a = 1` will cause `a` to be a Ruby object with an `Integer` value `1` and something like `int a = 1` will cause `a` to be of C type `int`.

## Integer

Integers are supported. Assigning an integer to a C type has the same effect as the assignment would in C code.
``` ruby
def foo
  float a = 3
  int b = -2
  char c = 34
end
```

## Float

Similar to integers.
``` ruby
def foo
  float i = 4.5
  double j = -32.66
  int c = 6.9
end
```

## Character

Characters can be specified with a single quote. If assigning to a Ruby object, `char` will be implicitly converted to a Ruby `String`.
``` ruby
def foo
  char c = 'a'

  return c
end
```

## String

Strings are specified with double quotes. Note that Ruby-like single quoted strings are _not_ supported in Rubex. String literals are C strings (`char*` arrays) by default but if you assign them to a Ruby object they are implicitly converted into Ruby strings.

For example:
``` ruby
def foo
  s = "hello world!"
  char *cs = "hello world!"

  return cs
end
```
The `char*` can be implicitly converted to Ruby object. Read the [Handling Strings](#handling-strings) section to know more about string inter-conversion.

## Ruby Literals

Apart from `String`, Rubex also supports creating basic Ruby objects like `Array`, `Hash` and `Symbol` from literals using the same familiar Ruby syntax.

### Ruby Symbol

Symbols are specified with `:` before the identifier.
``` ruby
def foo
  a = :hello
  return a
end
```

### Ruby Array

Can be specified using `[]`. All members of the Array should be implicitly convertible to Ruby objects (like primitive C types or object). Putting instances of `struct` will lead to errors.
``` ruby
def foo
  a = [1,2,3,"hello", "world", :symbol]
  return a
end
```

### Ruby Hash

Hashes can be specified with `{}`.

Example:
``` ruby
def foo
  a = {
    :hello => "world",
    3 => 4,
    "foo" => :bar
  }

  return a
end
```

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

# Ruby Constants

Ruby constants can be specified using identifiers that start with capital letters. Since many C libraries contain functions or macros that start with capital letters, the Rubex compiler will first search for such identifiers, and if it does not find any, will assume that the identifier is a Ruby constant.
``` ruby
def foo
  a = String.new("foo bar")
  return a
end
```

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

Exception handling in Rubex can be done exactly like that in Ruby. No more dealing with `rb_protect()` or [complex tutorials](https://silverhammermba.github.io/emberb/c/#exceptions) on error handling in C extensions.

Just simply use `begin-rescue-else-ensure` blocks the way you would in Ruby. You can also make variable declarations inside these blocks and any value you define inside can be used outside too, just like in Ruby.

Example:
``` ruby
def foo(int n)
  begin
    raise ArgumentError if n == 1
    raise SyntaxError if n == 2
  rescue ArgumentError
    n += 1
  rescue SyntaxError
    n += 2
  else
    n += 5
  ensure
    n += 10
  end

  return n
end
```

# 'Attach' Classes

Rubex introduces a special syntax that allows you to directly interface Ruby with C structs using some special language constructs, called 'attach' classes. These are normal Ruby classes and can be instantiated and used just like any other Ruby class, but with one caveat - they are permanently attached to a C struct and implicitly interface this struct with the Ruby VM.

Let me demonstrate with an example:
``` ruby
# file: structs.rubex
lib "rubex/ruby"; end

struct mp3info
  int id
  char* title
end

class Music attach mp3info
  def initialize(id, title)
    mp3info* mp3 = data$.mp3info

    mp3.id = id
    mp3.title = title
  end

  def id
    return data$.id
  end

  def title
    return data$.title
  end

  cfunc void deallocate
    xfree(data$.mp3info)
  end
end
```
This program can be used in a Ruby script like this:
``` ruby
require 'structs.so'

id = 1
title = "CAFO"
m = Music.new id, title
puts m.id, m.title
```

The above example has some notable Rubex constructs:

## The attach keyword

The 'attach' keyword is a special keyword that is used for associating a particular struct with a Ruby class. Once this keyword is used, the Rubex compiler will take care of allocation, deallocation and fetching of the struct, i.e. it will add calls to various functions essential for interfacing the struct with Ruby VM and the Garbage Collector. It will also create the `ruby_data_type_t` struct that [holds all the information](https://ruby-doc.org/core-2.3.0/doc/extension_rdoc.html#label-C+struct+to+Ruby+object)for interfacing structs with the Ruby VM, for example pointers to the marking and freeing functions.

In the above case, `attach` creates tells the class `Music` that it will be associated with a C struct of type `mp3info`.

## The data$ variable

The `data$` variable is a special variable keyword that is available _only_ inside attach classes. The `data$` variable allows access to the `mp3info` struct. In order to do this, it makes available a **pointer** to the struct that is of the same name as the struct (i.e. `mp3info` for `struct mp3info` or `foo` for `struct foo`). This pointer to the struct can then be used for reading or writing elements in the struct.

Read the 'Internals' section in [CONTRIBUTING](CONTRIBUTING.md) if you want to know more about the `data$` variable.

## Special C functions in attach classes

In most cases, the default configuration of the attach classes will suffice and you will not need to write any of the functions listed below by yourself (Rubex will write those functions in C for you), but if in some special cases where customization by the user is necessary, it can be done using some special functions that are translated directly into the relevant functions that need to interface with the Ruby VM for successfully interfacing a struct.

### deallocate

This is the only function that you must write by yourself, since a lot of GC deallocation depends upon specific data inside the struct and it is best if specified by the user.

Once you are done using an instance of your newly created attach class, Ruby's GC will want to clean up the memory used by it so that it can be used by other objects. In order to not have any memory leaks later, it is important to tell the GC that the memory that was used up by the `mp3info` struct needs to be freed. This freeing up of memory should be done inside the `deallocate` function.

The `xfree` function, which is the standard memory freeing function provided by the Ruby interpreter is used for this purpose.

### allocate

### memcount

### get_struct

### gc_mark

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

# Handling Strings

For purposes of optimization and compatibility with C, Rubex makes certain assumptions about strings. When you assign a Ruby object to a `char*`, Rubex will automatically pass a pointer to the C string contained inside the object to the `char*`, thereby increasing the efficiency of operations on the string. The resulting string is a regular `\0` delimited C string.

It should be noted that strings MUST use the double quotation syntax (`""`) and not single quotes in all cases. Single quote is reserved for use by C `char` data. For example, to assign a literal value to a C char, you can write `char a = 'b'`, to assign a literal C string to a `char*` array, use `char* a = "hello"`.

# Differences from C

* Rubex does not have dereferencing operator (`*`). Instead use `[0]` to access values pointed to by pointers.
* There is no `->` operator for accessing struct elements from a pointer to a struct. Use the `.` operator directly.

# Differences from Ruby

* The `return` statement must be specified to return a value. Unlike Ruby, Rubex does not return the last expression in a method.
* Specify arguments for method definitions inside round brackets.
* As of now, there is very limited support for metaprogramming.
* Blocks are not supported yet, though this will change by v0.2.

# Limitations

Most of the below limitations are temporary and will be taken care of in future versions:

* The `require` statement is currently not supported.
* Multi-file Rubex programs are not yet possible.
