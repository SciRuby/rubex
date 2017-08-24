# Rubex

Rubex is a Ruby-like language for writing Ruby C extensions.

Rubex is a language that makes writing CRuby C extensions as simple as writing Ruby. It does this by providing a syntax that is the perfect blend of the elegance of Ruby and the power of C. Rubex compiles to C and implicitly interfaces with the Ruby VM in a manner that is completely transparent to the programmer.

Rubex keeps you happy even when writing C extensions.

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
    arr = []

    while i < n do
      temp = current
      current = current + prev
      prev = temp
      arr.push(prev)
      i += 1
    end

    return arr
  end
end
```

Notice the only difference between the above Rubex code and Ruby is the specification of explicit `int` types for the variables. Above Rubex code will automatically compile into C code and will also implicitly interface with the Ruby VM without you having to remember any of the APIs.

Rubex also takes care of the initial setup and compilation of the C files, so all you need to do is execute a bunch of commands and your extension is up and running!

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

# Tutorial

Give yourself 5 min and go through the [TUTORIAL](docs/tutorial.md). Convert a part of your C extension to Rubex and see the jump in cleanliness and productivity for yourself.

# Syntax

Read the full Rubex reference in [REFERENCE](docs/reference.md).

# Roadmap

See the [CONTRIBUTING](CONTRIBUTING.md) and the GitHub issue tracker for future features.

# Acknowledgements

* The Ruby Association (Japan) for providing the initial funding for this project through the Ruby Association Grant 2016.
* Koichi Sasada (@ko1) and Kenta Murata (@mrkn) for their support and mentorship throughout this project.
