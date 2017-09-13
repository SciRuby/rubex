---
layout: page
title: Tutorial
---

Here's a quick tutorial of Rubex to get you up and started. Once you're through, take a moment to convert one of your C extensions to Rubex and see the difference in speed of development and simplicity.

<!-- MarkdownTOC autolink="true" bracket="round" -->

- [Basics of Rubex](#basics-of-rubex)
  - [Rubex Hello World](#rubex-hello-world)
  - [String#blank?](#stringblank)
- [Calling C Functions](#calling-c-functions)
- [C Functions](#c-functions)
- ['Attach' Classes](#attach-classes)
- [Error Handling](#error-handling)
- [Using Rubex Inside A Gem](#using-rubex-inside-a-gem)
- [Examples](#examples)
  - [Interfacing C structs](#interfacing-c-structs)
  - [Fully Functional Ruby Gem](#fully-functional-ruby-gem)

<!-- /MarkdownTOC -->

# Basics of Rubex

The Rubex syntax is very close to that of Ruby. In most use cases you can simply add a static types to variables and you're good to go. Rubex files have an extension `.rubex`.

Before starting, make sure you've installed Rubex with `gem install rubex`.

## Rubex Hello World

In a Rubex file titled `hello_word.rubex` paste the following code:
``` ruby
def hello_world
  print "Hello world!"
end
```

Now the use the `rubex` binary to compile the above program:
```
rubex hello_world.rubex
```

This will generate a folder called `hello_world` that will contain the files `extconf.rb` and `hello_world.c`. Now run the following:
```
cd hello_world
ruby extconf.rb
make
```

This will generate a shared object file called `hello_world.so` that can be used in any normal Ruby script like so:
``` ruby
require_relative 'hello_world.so'

hello_world
```

## String#blank?

Sam Saffron's famous [`fast_blank`](https://github.com/SamSaffron/fast_blank) gem is something that most Rubyists probably use a lot of times in their daily life. It is also a classic example of porting a Ruby gem to a C extension for reasons of speed.

Here's the Rubex version of fast_blank:
``` ruby
class String
  def blank?(string)
    char *s = string
    int i = 0

    while i < string.size do
      return false if s[i] != ' '
    end

    return true
  end
end
```

As you can see above, Rubex can implicitly convert between Ruby objects and C data types (like a Ruby `String` into a `char*` C array).

# Calling C Functions

One of the primary uses of Rubex is making it easy for interfacing with C libraries. This can be done by using the `lib` keyword at the top of a Rubex file.

So say for example, you want to interface some functions from the `math.h` C header file. In order to do this, you first list out the prototypes of the functions that you want to interface inside `lib`, and then you can use these functions in your program.
``` ruby
lib "<math.h>"
  double cos(double)
  double sin(double)
end

class CMath
  def f_sin(num)
    return sin(num)
  end

  def f_cos(num)
    return cos(num)
  end
end
```

These functions can be used in a similar manner to our hello_world program above. Keep in mind that you cannot (yet) have function names in your Rubex program that have the same name as that of the external C functions. This will cause name clashes and malfunction.

Read what you can do more with `lib` in the [REFERENCE](reference.md).

# C Functions

Apart from Ruby class methods and instance methods, Rubex allows you to define 'C functions' that are only accessible inside classes from within Rubex. These functions _cannot_ be accessed from an external Ruby script.

C functions are defined used the `cfunc` keyword. You also need to specify the return type of the function along with its definition. For example:
``` ruby
class CFunctionTest
  def foo(int n)
    return bar(n)
  end

  # bar is a C function.
  cfunc int bar(int n)
    return n + 5
  end
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

### The attach keyword

The 'attach' keyword is a special keyword that is used for associating a particular struct with a Ruby class. Once this keyword is used, the Rubex compiler will take care of allocation, deallocation and fetching of the struct (more about this in the [REFERENCE](reference.md)). The user only needs to concern themselves with using and allocating the data inside the struct.

In the above case, `attach` creates tells the class `Music` that it will be associated with a C struct of type `mp3info`.

### The data$ variable

The `data$` variable is a special variable keyword that is available _only_ inside attach classes. The `data$` variable allows access to the `mp3info` struct. In order to do this, it makes available a **pointer** to the struct that is of the same name as the struct (i.e. `mp3info` for `struct mp3info` or `foo` for `struct foo`). This pointer to the struct can then be used for reading or writing elements in the struct.

### The deallocate C function

Once you are done using an instance of your newly created attach class, Ruby's GC will want to clean up the memory used by it so that it can be used by other objects. In order to not have any memory leaks later, it is important to tell the GC that the memory that was used up by the `mp3info` struct needs to be freed. This freeing up of memory should be done inside the `deallocate` function.

The `xfree` function, which is the standard memory freeing function provided by the Ruby interpreter is used for this purpose.

# Error Handling

Rubex greatly simplifies error handling for C extensions. It now gives you the full power of a Ruby `begin-rescue-else-ensure` block. You can also define variables inside these blocks!

Here's an example:
``` ruby
def error_example(int n)
  begin
    raise ArgumentError if n == 1
    raise SyntaxError if n == 2
  rescue ArgumentError
    n += 10
  rescue SyntaxError
    n += 20
  ensure
    n += 5
  end

  return n
end
```

# Using Rubex Inside A Gem

Rubex ships with pre-built rake tasks that can be for compiling a Rubex file. In order to use these, simply drop in the following code into your `Rakefile`:
``` ruby
require 'rubex/rake_task'

Rubex::RakeTask.new('hello_world')
```

Above rake task assumes that you use the standard Ruby gem structure:
```
|-- ext
|   `-- hello_world
|       `-- hello_world.rubex
|-- lib
`-- Rakefile
```

Calling `rake compile` will generate `hello_world.c` and `extconf.rb` in your `ext` folder and place `hello_world.so` in your `lib/` folder which you directly use with a simple `require`.

# Examples

## Interfacing C structs

[This example](https://github.com/v0dro/rubex/tree/master/examples/c_struct_interface) is a program that interfaces with a C struct and creates reader and writer methods for C struct elements through a Ruby interface.

## Fully Functional Ruby Gem

See the [rcsv example](https://github.com/v0dro/rubex/tree/master/examples/rcsv%20wrapper/rcsv) for a fully functional rubygem that wraps around the [libcsv](https://sourceforge.net/projects/libcsv/) C library for parsing CSV files.
