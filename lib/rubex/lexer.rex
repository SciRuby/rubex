class Rubex::Lexer
macros
  # reserved words

  DEF             /def/
  RETURN          /return/
  PRINT           /print/
  IF              /if/
  ELSE            /else/
  ELSIF           /elsif/
  THEN            /then/
  STATIC_ARRAY    /StaticArray/
  FOR             /for/
  WHILE           /while/
  DO              /do/
  EACH            /each/
  TRUE            /true/
  FALSE           /false/
  NIL             /nil/
  STRUCT          /struct/
  UNION           /union/
  ALIAS           /alias/

  IDENTIFIER      /[a-zA-Z_][a-zA-Z_0-9]*/
  LPAREN          /\(/
  RPAREN          /\)/
  LSQUARE         /\[/
  RSQUARE         /\]/
  NL              /\n/
  COMMA           /,/
  SQUOTE          /'/
  SCOLON          /;/
  INTEGER         /-?\d+/
  FLOAT           /-?\d+\.\d+/
  DOT             /\./
  QMARK           /\?/

  # operators

  EXPO            /\*\*/
  EXPOASSIGN      /\*\*=/
  STAR            /\*/
  STARASSIGN      /\*=/
  DIVIDE          /\//
  DIVIDEASSIGN    /\/=/
  PLUS            /\+/
  PLUSASSIGN      /\+=/
  MINUS           /\-/
  MINUSASSIGN     /\-=/
  MODULUS         /%/
  MODULUSASSIGN   /%=/
  ASSIGN          /=/
  NEQ             /!=/
  EQ              /==/
  LT              /</
  LTEQ            /<=/
  GT              />/
  GTEQ            />=/
  ANDOP           /&&/
  OROP            /\|\|/
  BANG            /!/

rules

  # literals

  /'.\'/          { [:tSINGLE_CHAR, text] }
  /#{FLOAT}/      { [:tFLOAT, text] }
  /#{INTEGER}/    { [:tINTEGER, text] }

  # Reserved words

  /#{DEF}\ /    { [:kDEF   , text] }
  /end/       { [:kEND   , text] }
  /#{RETURN}/ { [:kRETURN, text] }
  /#{PRINT}/  { [:kPRINT , text] }
  /#{IF}/     { [:kIF    , text] }
  /#{ELSIF}/  { [:kELSIF , text] }
  /#{ELSE}/   { [:kELSE  , text] }
  /#{THEN}/   { [:kTHEN  , text] }
  /#{STATIC_ARRAY}/ { [:kSTATIC_ARRAY, text] }
  /#{FOR}/    { [:kFOR, text]    }
  /#{WHILE}/  { [:kWHILE, text]  }
  /#{DO}/     { [:kDO, text]     }
  /#{TRUE}/   { [:kTRUE, text]   }
  /#{FALSE}/  { [:kFALSE, text]  }
  /#{NIL}/    { [:kNIL, text]    }

  # Method hacks

  /#{DOT}#{EACH}/ { [:kDOT_EACH, text] }

  # Data Types

  /unsigned long long int/ { [:kDTYPE_ULLINT, text] }
  /unsigned long int/      { [:kDTYPE_ULINT, text] }
  /unsigned int/           { [:kDTYPE_UINT, text] }
  /long int/               { [:kDTYPE_LINT, text] }
  /long long int/          { [:kDTYPE_LLINT, text] }
  /char/                   { [:kDTYPE_CHAR, text] }
  /i8/                     { [:kDTYPE_I8, text] }
  /i16/                    { [:kDTYPE_I16, text] }
  /i32/                    { [:kDTYPE_I32, text] }
  /i64/                    { [:kDTYPE_I64, text] }
  /u8/                     { [:kDTYPE_UI8, text] }
  /u16/                    { [:kDTYPE_UI16, text] }
  /u32/                    { [:kDTYPE_UI32, text] }
  /u64/                    { [:kDTYPE_UI64, text] }
  /int/                    { [:kDTYPE_INT, text] }
  /f32/                    { [:kDTYPE_F32, text] }
  /float/                  { [:kDTYPE_F32, text] }
  /f64/                    { [:kDTYPE_F64, text] }
  /double/                 { [:kDTYPE_F64, text] }
  /object/                 { [:kDTYPE_ROBJ, text] }
  # /long double/            { [:kDTYPE_LF64, text] }
  # /long f64/               { [:kDTYPE_LF64, text] }

  # Keywords

  /#{STRUCT}\ / { [:kSTRUCT, text] }
  /#{UNION}\ /  { [:kUNION, text]  }
  /#{ALIAS}\ /  { [:kALIAS, text]  }

  /#{IDENTIFIER}/         { [:tIDENTIFIER, text] }
  /#{LPAREN}/             { [:tLPAREN, text] }
  /#{RPAREN}/             { [:tRPAREN, text] }
  /#{LSQUARE}/            { [:tLSQUARE, text] }
  /#{RSQUARE}/            { [:tRSQUARE, text] }
  /#{COMMA}/              { [:tCOMMA, text] }
  /#{SCOLON}/             { [:tSCOLON, text] }
  /#{NL}/                 { [:tNL, text] }
  /#{QMARK}/              { [:tQMARK, text]}
  /#{DOT}/                { [:tDOT, text]    }

  # operators

  /#{PLUSASSIGN}/       { [:tOP_ASSIGN, text]}
  /#{MINUSASSIGN}/      { [:tOP_ASSIGN, text]}
  /#{STARASSIGN}/       { [:tOP_ASSIGN, text]}
  /#{DIVIDEASSIGN}/     { [:tOP_ASSIGN, text]}
  /#{EXPOASSIGN}/       { [:tOP_ASSIGN, text]}
  /#{MODULUSASSIGN}/    { [:tOP_ASSIGN, text]}
  /#{PLUS}/             { [:tPLUS, text]}
  /#{MINUS}/            { [:tMINUS, text]}
  /#{STAR}/             { [:tSTAR, text]}
  /#{DIVIDE}/           { [:tDIVIDE, text]}
  /#{EXPO}/             { [:tEXPO, text]}
  /#{MODULUS}/          { [:tMODULUS, text]}
  /#{EXPO}/             { [:tEXPO, text]}
  /#{EQ}/               { [:tEQ, text]  }
  /#{NEQ}/              { [:tNEQ, text]  }
  /#{ASSIGN}/           { [:tASSIGN, text] }
  /#{BANG}/             { [:tBANG, text] }

  /#{LTEQ}/       { [:tLTEQ, text] }
  /#{LT}/         { [:tLT, text] }

  /#{GTEQ}/       { [:tGTEQ, text] }
  /#{GT}/         { [:tGT, text] }

  /#{ANDOP}/      { [:tANDOP, text] }
  /#{OROP}/       { [:tOROP, text] }

  # whitespace

  /^\n\s*$/
  /\s+/

inner
  def do_parse
    # this is a stub since oedipus lex uses this internally.
  end
end # Rubex::Lexer
