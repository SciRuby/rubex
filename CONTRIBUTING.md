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
