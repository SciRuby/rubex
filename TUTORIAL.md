# Rubex tutorial

Here's a quick tutorial of Rubex to get you up and started. Once you're through, take a moment to convert one of your C extensions to Rubex and see the difference in speed of development and simplicity.

<!-- MarkdownTOC autolink="true" bracket="round" -->

- [A simple Ruby method](#a-simple-ruby-method)

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

## blank?

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

Read what you can do more with `lib` in the [REFERENCE](REFERENCE.md).

# 'Attach' Classes

# Error Handling

# Handling Strings

For purposes of optimization and compatibility with C, Rubex makes certain assumptions

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

[This example]() is a program that interfaces with a C struct and creates getters and setters for C struct elements through a Ruby interface.

## Fully Functional Ruby Gem

See the [rcsv example]() for a fully functional rubygem that wraps around the [libcsv]() C library for parsing CSV files.
