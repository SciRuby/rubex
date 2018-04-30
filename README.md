# Rubex

Rubex is a Ruby-like language for writing Ruby C extensions.

Rubex is a language that makes writing CRuby C extensions as simple as writing Ruby. It does this by providing a syntax that is the perfect blend of the elegance of Ruby and the power of C. Rubex compiles to C and implicitly interfaces with the Ruby VM in a manner that is completely transparent to the programmer.

Rubex keeps you happy even when writing C extensions.

# Status

[![Gem Version](https://badge.fury.io/rb/rubex.svg)](https://badge.fury.io/rb/rubex)
[![Open Source Helpers](https://www.codetriage.com/v0dro/rubex/badges/users.svg)](https://www.codetriage.com/v0dro/rubex)
[![Build Status](https://travis-ci.org/SciRuby/rubex.svg?branch=master)](https://travis-ci.org/SciRuby/rubex)

# Table of Contents

<!-- MarkdownTOC autolink="true" bracket="round"-->

- [Quick Introduction](#quick-introduction)
- [Installation](#installation)
- [Usage](#usage)
- [Tutorial](#tutorial)
- [Syntax](#syntax)
- [Roadmap](#roadmap)
- [Acknowledgements](#acknowledgements)

<!-- /MarkdownTOC -->

# Quick Introduction

Consider this Ruby code for computing a fibonnaci series and returning it in an Array:
``` ruby
class Fibonnaci
  def compute(n)
    i = 1, prev = 1, current = 1, temp
    arr = []

    while i < n do
      temp = current
      current = current + prev
      prev = temp
      arr.push(prev)
      i += 1
    end

    arr
  end
end
```

If you decide to port this to a C extension, the code will look like so:
``` c
#include <ruby.h>
#include <stdint.h>

void Init_a ();
static VALUE Fibonnaci_compute (int argc,VALUE* argv,VALUE self);

static VALUE Fibonnaci_compute (int argc,VALUE* argv,VALUE self)
{
  int n,i,prev,current,temp;
  VALUE arr;

  if (argc < 1) {
    rb_raise(rb_eArgError, "Need 1 args, not %d", argc);
  }

  n       = NUM2INT(argv[0]);
  i       = 1;
  prev    = 1;
  current = 1;
  arr     = rb_ary_new2(0);

  while (i < n)
  {
    temp = current;
    current = current + prev;
    prev = temp;
    rb_funcall(arr, rb_intern("push"), 1 ,INT2NUM(prev));
    i = i + 1;
  }

  return arr;
}

void Init_a ()
{
  VALUE cls_Fibonnaci;

  cls_Fibonnaci = rb_define_class("Fibonnaci", rb_cObject);

  rb_define_method(cls_Fibonnaci ,"compute", Fibonnaci_compute, -1);
}
```

However, if you decide to write a C extension using Rubex, the code will look like this!:
``` ruby
class Fibonnaci
  def compute(int n)
    int i = 1, prev = 1, current = 1, temp
    array = []

    while i < n do
      temp = current
      current = current + prev
      prev = temp
      array.push(prev)
      i += 1
    end

    return array
  end
end
```

Notice the only difference between the above Rubex code and Ruby is the specification of explicit `int` types for the variables. Above Rubex code will automatically compile into C code and will also implicitly interface with the Ruby VM without you having to remember any of the APIs.

Rubex also takes care of the initial setup and compilation of the C files, so all you need to do is execute a bunch of commands and your extension is up and running!

# Installation
Requires Ruby version >= 2.3.0

Install with:
```
gem install rubex
```

# Usage

Installing the gem will also install the `rubex` binary. You can now write a Rubex file (with a `.rubex` file extension) and compile it into C code using the following commands.

## Commands

#### Generate

Create all the necessary files for the C extension.

```
rubex generate file_name.rubex
```

```
Options
  -f, [--force]            # replace existing files and directories
  -d, [--dir=DIR]          # specify a directory for generating files
  -i, [--install]          # automatically run install command after generating Makefile
  -g, [--debug]            # enable debugging symbols when compiling with GCC
```

#### Install

Run the `make` utility on generated files.

```
rubex install path/to/generated/directory
```

#### Help

Describe available commands or one specific command

```
rubex help [COMMAND]
```

## Manual Usage
If you want to manually generate the files, you can do that with:

```
rubex file_name.rubex
```

This will produce the translated C code and an `extconf.rb` file inside a directory called `file_name`. CD into the directory, and run the `extconf.rb` file with:
```
ruby extconf.rb
```

This will produce a `Makefile`. Run `make` to compile the generated C file and generate a `.so` shared object file that can be used in any Ruby script.

# Tutorial

Give yourself 5 min and go through the [TUTORIAL](TUTORIAL.md). Convert a part of your C extension to Rubex and see the jump in cleanliness and productivity for yourself.

# Syntax

Read the full Rubex reference in [REFERENCE](REFERENCE.md).

# Differences with Ruby

Although Rubex tries its best to support the Ruby syntax as much as possible, in some cases it is not feasible or necessary to provide full support. Following is a list of differences between Ruby and Rubex syntax:

* All methods in Rubex (including `require` calls) must use round brackets for arguments.
* No support Ruby blocks.
* No support for class variables.
* All methods and functions in Rubex must use the `return` statement for returning values.

# Roadmap

See the [CONTRIBUTING](CONTRIBUTING.md) and the GitHub issue tracker for future features.

# Acknowledgements

* The Ruby Association (Japan) for providing the initial funding for this project through the Ruby Association Grant 2016.
* Koichi Sasada (@ko1), Kenta Murata (@mrkn) and Naotoshi Seo (@sonots) for their support and mentorship throughout this project.
* Fukuoka Ruby Award 2017.
* Tokyo Institute of Technology.
