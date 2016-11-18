class Rubex::Lexer
macros
  DEF             /def/
  RETURN          /return/

  IDENTIFIER      /[a-z_][a-zA-Z_0-9]*/
  LPAREN          /\(/
  RPAREN          /\)/
  NL              /\n/
  COMMA           /,/

  # operators
  EXPO            /\*\*/
  MULTIPLY        /\*/
  DIVIDE          /\//
  PLUS            /\+/
  MINUS           /\-/
  MODULUS         /%/
  EQUAL           /=/
rules
  /#{DEF}/  { [:kDEF, text] }
  /end/  { [:kEND, text]  }
  /#{RETURN}/ { [:kRETURN, text] }

  /i32/           { [:kDTYPE_I32, text] }

  /#{IDENTIFIER}/ { [:tIDENTIFIER, text] }
  /#{LPAREN}/     { [:tLPAREN, text] }
  /#{RPAREN}/     { [:tRPAREN, text] }
  /#{NL}/         { [:tNL, text] }
  /#{COMMA}/      { [:tCOMMA, text] }

  # operators

  /#{PLUS}/       { [:tPLUS, text]}
  /#{MINUS}/      { [:tMINUS, text]}
  /#{MULTIPLY}/   { [:tMULTIPLY, text]}
  /#{DIVIDE}/     { [:tDIVIDE, text]}
  /#{EXPO}/       { [:tEXPO, text]}
  /#{MODULUS}/    { [:tMODULUS, text]}
  /#{EXPO}/       { [:tEXPO, text]}

  # whitespace

  / /             {}
inner
  def do_parse
    # this is a stub since oedipus lex uses this internally.
  end
end # Rubex::Lexer