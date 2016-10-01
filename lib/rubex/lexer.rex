class Rubex::Lexer
macros
  DEF             /def/
  RETURN          /return/

  IDENTIFIER      /[a-z_][a-zA-Z_0-9]*/
  LPAREN          /\(/
  RPAREN          /\)/
  NL              /\n/
  COMMA           /,/
  PLUS            /\+/
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
  /#{PLUS}/       { [:tPLUS, text]}


  / /             {}
inner
  def do_parse
    # this is a stub since oedipus lex uses this internally.
  end
end # Rubex::Lexer