require_relative 'if_block/helper'
module Rubex
  module AST
    module Statement
      class IfBlock < Base
        attr_reader :expr, :statements, :if_tail
        include Rubex::AST::Statement::IfBlock::Helper

        def initialize(expr, statements, if_tail, location)
          super(location)
          @expr = expr
          @statements = statements
          @if_tail = if_tail
        end

        def analyse_statement(local_scope)
          @tail_exprs = if_tail_exprs # FIME: gets current expr too. make descriptive.
          @tail_exprs.each do |tail|
            tail.analyse_types local_scope
            tail.allocate_temps local_scope
          end
          @tail_exprs.each do |tail|
            tail.release_temps local_scope
          end
          super
        end

        def if_tail_exprs
          tail_exprs = []
          temp = self
          while temp.respond_to?(:if_tail) &&
                !temp.is_a?(Rubex::AST::Statement::IfBlock::Else)
            tail_exprs << temp.expr
            temp = temp.if_tail
          end

          tail_exprs
        end

        def generate_code(code, local_scope)
          @expr.generate_evaluation_code(code, local_scope)
          @tail_exprs.each do |tail|
            tail.generate_evaluation_code(code, local_scope)
          end
          generate_code_for_statement 'if', code, local_scope, self

          tail = @if_tail
          while tail
            if tail.is_a?(Elsif)
              generate_code_for_statement 'else if', code, local_scope, tail
            elsif tail.is_a?(Else)
              generate_code_for_statement 'else', code, local_scope, tail
            end
            tail = tail.if_tail
          end

          @tail_exprs.each do |tail|
            tail.generate_disposal_code code
          end
        end
      end
    end
  end
end
