# Rubex

rubex - A Crystal-inspired language for writing Ruby extensions.

# Overview

Rubex is a language that makes writing CRuby C extensions as simple as writing Ruby itself. It is a super set of Ruby with some special syntax that is specially developed for making it easy for binding C libraries and easily porting your Ruby code to C for increased speed.

It allows you to mix Ruby data types and C data types in the same program.

Rubex is complimentary to Ruby. It DOES NOT aim to be a replacement for Ruby.

# Installation

The gem as of now has not reached v0.1. However, you can try it out with:
```
git clone https://github.com/v0dro/rubex.git
cd rubex
bundle install
rake install
```

# Usage

Installing the gem will also install the `rubex` binary. You can now write a Rubex file (with a `.rubex` file extension) and compile it into C code with:
```
rubex file_name.rubex
```

This will produce the translated C code and an `extconf.rb` file inside a directory called `file_name`. CD into the directory, and run the `extconf.rb` file with:
```
ruby extconf.rb
```

This will produce a `Makefile`. Run `make` to compile the generated C file and generate a `.so` shared object file that can be used in any Ruby script.

# Sample Programs

A sample Rubex program that computes the first `n` fibonnaci numbers and prints each of them would look like this:
``` ruby
class Fibonnaci
  def compute(int n)
    int i = 1
    int prev = 1
    int current = 1
    int temp

    print 1, "\n"
    print 1, "\n"

    while i < n do
      temp = current
      current = current + prev
      prev = temp
      print current, "\n"

      i += 1
    end
  end
end
```

Notice that the only difference between Rubex and this program is that we have defined the `compute` method to receive a number of type `int`. The variables `i`, `prev`, `current` and `temp` are defined as `int` using a syntax very similar to C.

You can now run the above program using a script like this:
``` ruby
require_relative 'fibo.so'

Fibonnaci.new.compute(10)
```

This will print the first 10 fibonnaci numbers on your terminal.

Let us now dive deeper into the Rubex syntax.

# Syntax

Most of the Rubex syntax looks exactly like Ruby - but with certain add-ons that allow it to easily compile to C. Read on for an overview.

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
lib "<math.h>" do
  double sin(double)
  double cos(double)
end

class Trigonometry
  def math_sin(double n)
    return sin(n)
  end

  def math_cos(double n)
    return cos(n)
  end
end
```

And you're done!

You can simply call these functions through a Ruby script that uses the `math_sin` and/or `math_cos` methods inside the `Trigonometry` class.

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

### Implicit type conversions

Rubex will implicitly convert most primitive C types like `char`, `int` and `float` to their equivalent Ruby types and vice versa. However, types conversions for user defined types like structs and unions are not supported.

# Roadmap for v0.1

See the [wiki](https://github.com/v0dro/rubex/wiki/Rubex-v0.1-goals) for a roadmap of Rubex for v0.1

# Acknowledgements

My sincere thanks to the Ruby Association (Japan) for providing the initial funding for this project through the Ruby Association Grant 2016.