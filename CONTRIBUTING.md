# Table of Contents

<!-- MarkdownTOC autolink="true" bracket="round" -->

- [Setup](#setup)
- [Development notes](#development-notes)
- [Important data representations](#important-data-representations)
- [Internals](#internals)
  - [Attach classes](#attach-classes)
- [Future work](#future-work)

<!-- /MarkdownTOC -->

# Setup

If you wish to contribute to Rubex, you can setup rubex on your system with the following commands:
```
bundle install
rake install
```

Then you can compile a Rubex file with this:
```
rubex file_name.rubex
```

# Development notes

Couple of conventions that I followed when writing the code:
* All the statements contain methods:
  - analyse_statement(local_scope)
  - generate_code(code, local_scope)
* Expressions contain methods:
  - analyse_statement(local_scope)
  - c_code(local_scope)

Sometimes it can so happen that an expression can consist simply of a single variable (like `if (a)`) or be a full expression (like `if (a == b)`). In the first case, the `a` is just read as an `IDENTIFIER` by the parser. In the second case, `a == b` is read as an `expr` and is stored in the AST as `Rubex::AST::Expression`.

Now you might be thinking why expressions should also have a `analyse_statement` method, that's just for maintaining uniformity between exprs and stmts (maybe that should be just `analyse`?).

When writing the `<=>` operator under Rubex::DataType classes, I have been forced to assume that `Int` is 32 bits long since I have not yet incorporated a way to figure out the number of bits used by a particular machine for representing an `int`. It will be changed later to make it machine-dependent.

# Important data representations

### Data format for holding parsed variables in declarations and arguments

This consists of a hash that looks like this:
```
{
  dtype: ,
  variables: [{}]
}
```

The `:variables` field might be `nil` in case of a function declaration in which case it is not necessary to specify the name of the variable.

The `:variables` key maps to a value that is an Array of Hashes that contains a single Hash:
```
{
  ptr_level:,
  value:,
  ident: identity
}
```

`identity` can be a Hash in case of a function pointer argument, or a simple String in case its an identifier, or an `ElementRef` if specifying an array of elements.

If Hash, it will look like this:
```
{
  name:,
  return_ptr_level:,
  arg_list:
}
```

# Internals

## Attach classes



# Future work

The following features in Rubex need to be implemented or can be made better:

* Ability to have Ruby-style method arguments without parenthesis.
* Multiline conditionals in the condition of if-elsif statements.
* Special treatment for VALUE C arrays by marking each element with GC.
* Checks for return statement. No return statement or wrong return type should raise error/warning.
* Compile time checking of types passed into functions and methods.
* Perform type checks in C before implicit conversion between Ruby and C types.
* Ability to define function at any location in the file witout caring for when it will be actually used.
* Error checking for dereferencing of void pointer.
* Prohibit structs (vector types) in if statements via compile time checks.
* Ability to provide default values to method arguments.
* Ability to write Rubex programs spanning multiple files.
* If a Ruby method and extern C function have the same name the program malfunctions. Either namespace C functions or disallow Ruby methods with same names as extern C functions.
* Clean up classes under Statement such that they don't have attr_reader's like `:name` and `:type` which are really not a part of statement attributes.
* Support for multi-file programs (maybe using `require`?).
* Refactor classes to cleaner support for compound types like CFunctions and simple struct pointers that have the base type nested just one level deep.
