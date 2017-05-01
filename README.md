# Rubex

rubex - A Crystal-inspired language for writing Ruby extensions.

# Overview

Rubex is a language that makes writing CRuby C extensions as simple as writing Ruby itself. It is a super set of Ruby with some special syntax that is specially developed for making it easy for binding C libraries and easily porting your Ruby code to C for increased speed.

It allows you to mix Ruby data types and C data types in the same program.

It DOES NOT aim to be a replacement for Ruby. It is complimentary to Ruby and is meant to give your Ruby.

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

This will produce the translated C code, an `extconf.rb` file and a `Makefile`. You can now run the `extconf.rb` file with:
```
ruby extconf.rb
```

Which will produce a `.so` file called `file_name.so`, which can then be used in any Ruby script.

# Syntax

A sample Rubex program that computes the 


All code that you write should be a



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

