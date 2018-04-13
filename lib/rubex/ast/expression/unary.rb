require_relative 'unary_base'
Dir[File.join(File.dirname(File.dirname(__FILE__)), "expression", "unary_base", "*.rb" )].each { |f| require f }
module Rubex
  module AST
    module Expression
      class Unary < Base
        OP_CLASS_MAP = {
          '&' => Rubex::AST::Expression::Ampersand,
          '-' => Rubex::AST::Expression::UnarySub,
          '!' => Rubex::AST::Expression::UnaryNot,
          '~' => Rubex::AST::Expression::UnaryBitNot
        }.freeze

        def initialize(operator, expr)
          @operator = operator
          @expr = expr
        end

        def analyse_types(local_scope)
          @expr = OP_CLASS_MAP[@operator].new(@expr)
          @expr.analyse_types local_scope
          @type = @expr.type
          super
        end

        def generate_evaluation_code(code, local_scope)
          @expr.generate_evaluation_code code, local_scope
        end

        def c_code(local_scope)
          code = super
          code << @expr.c_code(local_scope)
        end
      end
    end
  end
end
