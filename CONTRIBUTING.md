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
