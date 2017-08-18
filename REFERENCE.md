# Rubex (RUBy EXtension Language)

Rubex is a language designed to keep you happy even when writing C extension.

Read on for the full specifications of the Rubex language.

# Table of Contents
<!-- MarkdownTOC autolink="true" bracket="round"-->

- [Comments](#comments)
- [The Basics](#the-basics)
  - [Ruby instance methods](#ruby-instance-methods)
  - [Ruby class methods](#ruby-class-methods)
  - [C functions](#c-functions)
- [Interfacing with external C libraries](#interfacing-with-external-c-libraries)
- [Literals](#literals)
- [Data Types](#data-types)
  - [C pointers](#c-pointers)
- [Statements and Expressions](#statements-and-expressions)
  - [Implicit type conversions](#implicit-type-conversions)
  - [The print statement](#the-print-statement)
  - [Conditional statement \(if-elsif-else\)](#conditional-statement-if-elsif-else)
  - [Loops](#loops)
- [Callbacks](#callbacks)
- [Interfacing with C structs](#interfacing-with-c-structs)

<!-- /MarkdownTOC -->

## Comments

Similar to Ruby, comments in code can be made using `#`.

Example:
``` ruby
# This is a comment.
def funky(int j) # ...so is this.
  return j
end
```

## The Basics

The most basic that you can do in any language is to define and call methods and functions that do a specific job. For this purpose, Rubex supports three kinds of methods/functions:

* Ruby instance methods
* Ruby class methods
* C functions

Out of these Ruby instance and class methods are callable from external Ruby scripts, but C functions are callable ONLY FROM THE RUBEX CODE.

### Ruby instance methods

A Ruby instance method can be defined like so:
``` ruby
class Bar
  def funk
    print "oh funk!"
  end
end
```

When the file is compiled and included into a Ruby script, the funk method can be called using `Bar.new.funk`.

Internally, Rubex compiles this code to the equivalent C code and makes calls to `rb_define_method` from the [Ruby C API](https://docs.ruby-lang.org/en/2.1.0/README_EXT.html#label-Extending+Ruby+with+C) so that the method `funk` can be registered with the CRuby interpreter as being an instance method under the class `Bar`.

### Ruby class methods

Ruby class methods can be defined with the exact same syntax that you use in Ruby - by using the `self` keyword before a method name. For example:
``` ruby
# In a Rubex file

class Foo
  def self.bar(int a)
    return a + 1
  end
end
```
This will define a method callable as `Foo.bar(2)` from a Ruby script. Interconversions between primitive C types and Ruby types are performed implicitly.

### C functions

C functions can be scoped inside classes/modules like normal Ruby methods and will be accessible to both Ruby instance and class methods only inside the Rubex program. These functions are not individually accessible through an external Ruby script.

C functions can be defined using the `cfunc` keyword. Keep in mind that you will also need to specify the return data type of the function since it will ultimately be compiled to simple C function that returns a value of a particular type.

For example:
``` ruby
class Foo
  cfunc int baz(float d)
    int a = d / 5

    return a
  end

  def bar(float d)
    int c = baz(d)

    return c
  end
end
```

## Interfacing with external C libraries

One of the primary uses of Rubex is to make it extremely simple to interface Ruby with external C libraries. For example, say you want to interface the `sin()` and `cos()` functions from the `math.h` C header file.

You use the `lib` keyword of Rubex and do that easily like this:
``` ruby
lib "<math.h>"
  double sin(double)
end

class Trigonometry
  def math_sin(double n)
    return sin(n)
  end
end
```

You can simply call these functions through a Ruby script that uses the `math_sin` and/or `math_cos` methods inside the `Trigonometry` class.

## Literals

Rubex accepts number and string literals. If you do not specify the data type of a variable when assigning it to a literal, it will be automatically be converted to a Ruby object.

For example:
``` ruby
def literals_demo
  # Assigns int i as 44.
  int i = 44

  # The variable j will be assigned a Ruby Integer object with value 44.
  j = 44

  # The string will be implicitly converted to a Ruby String object.
  string = "This is a Ruby string."

  # This will stay on as a C string of type char*.
  char* c_str = "This is a C string."
end
```

## Data Types

Rubex supports most primitive C data types out of the box. Following are the ones supported and their respective Rubex keywords:

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

### C pointers

You can define pointers and pass them to functions just like you do in C. Pointers can be specified using the `*` operator and addresses of variables can be accessed using the `&` (address-of) operator.

Keep in mind that Rubex does not support the `*` operator for deferencing a pointer. You will need to use the `[]` operator and access the value of pointer with `[0]` (since accessing the value of a pointer is analogous to accessing the value of an array in C).

Here's an example of declaring an array and passing its address to a C function from a Ruby method:
``` ruby
class CPointersDemo
  def foo
    int *i
    int j = 55

    i = &j

    return bar(i)
  end

  cfunc int bar(int *i)
    int j = 5, sum
    int sum = j + i[0]

    return sum
  end
end
```

## Statements and Expressions

All expressions that are supported in Ruby are supported in Rubex. You can also intermingle C and Ruby types in the same expression, subject to some restrictions.

### Implicit type conversions

Rubex will implicitly convert most primitive C types like `char`, `int` and `float` to their equivalent Ruby types and vice versa. However, types conversions for user defined types like structs and unions are not supported.

### The print statement

The `print` statement makes it easy to print something to the console using C's `printf` function underneath. If it is passed a Ruby object instead of a C data type, the `#inspect` method will be called on the object and the resultant string will be printed. `print` can accept multiple comma-separated arguments and will concatenate them into a single string.
``` ruby
def print_demo(a, b)
  int i = 5

  print "Obj a is : ", a, ".", " b is: ", b, "... and i is: ", i 
end
```

### Conditional statement (if-elsif-else)

Similar to Ruby, conditionals in Rubex can be written as follows:
``` ruby
def foo(a)
  int i = 3

  return true if a == i
  return false
end
```

In the above case, since `a` is a Ruby object and `i` is an `int`, `i` will be implicitly converted into a Ruby `Integer` and the comparison with the `==` operator will take place as though the two variables are Ruby objects (`.send(:==)`).

If the expression in an `if` statements consists only of C variables, the values `0` and `NULL` (null pointer) are treated as 'falsey' and everything else is truthy (exactly like C).

However, in case you intermingle Ruby and C types, Rubex will use the convention used in Ruby, i.e. `nil` (NilClass) and `false` (FalseClass) are 'falsey' whereas everything else (including zero) is 'truthy'. `0` and `NULL` will NOT be treated as 'falsey' in this scenario.

### Loops

Rubex supports `while` and `for` loops that look exactly like their Ruby counterparts, but are internally translated to C for speed.

A `while` loop can be defined like so:
``` ruby
def while_loop_demo
  int i = 0

  while i < 10 do
    print i, "\n"
    i += 1
  end
end
```

Rubex has its own syntax for `for` loops that is slightly different than the Ruby syntax. These loops are translated directly to efficient C code:
``` ruby
def for_loop_demo
  int i, j
  j = 1
  for 0 < i <= 10 do
    j += i
  end

  return j
end
```

## Callbacks

Frequently, C libraries use C function pointers to pass functions to other functions as callbacks. Rubex supports this behaviour too.

A C function pointer for a function that returns an `int` and accepts two `int`s as arguments can be declared as:
```
int (*foo)(int, int)
```

You can also alias function pointers to something more readable with the `alias` statement:
```
alias foo = int (*)(int, int)
```

A sample program using C function pointers is demonstrated below:
``` ruby
cfunc int foo1(int a)
  return a + 1
end

cfunc int foo2(int a)
  return a + 2
end

cfunc int baz1(int a, int b)
  return a + b + 1
end

cfunc int baz2(int a, int b)
  return a + b + 2
end

cfunc int bar(int (*func1)(int), int (*func2)(int, int), int a, int b)
  int ans1
  int ans2

  ans1 = func1(a)
  ans2 = func2(a, b)

  return ans1 + ans2
end

class CFunctionPtrs
  def test_c_function_pointers(switch)
    alias goswim = int (*ernub)(int, int)
    int (*func_ptr1)(int)
    goswim func_ptr2
    int a = 1
    int b = 1

    if switch
      func_ptr1 = foo1
      func_ptr2 = baz1
    else
      func_ptr1 = foo2
      func_ptr2 = baz2
    end

    return bar(func_ptr1, func_ptr2, a, b)
  end
end
```

## Interfacing with C structs