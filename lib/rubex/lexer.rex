module Rubex
class Lexer
macro
  BLANK         /\s+/
  DIGIT         /\d+/
rule

inner
  def do_parse
    # this is a stub since oedipus lex uses this internally.
  end
end # Lexer
end # Rubex