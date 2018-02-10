module Rubex
  module AST
    module Expression
      class AnalysedElementRef < Base
        def initialize(element_ref)
          @element_ref = element_ref
          @pos = @element_ref.pos
          @entry = @element_ref.entry
          @name = @element_ref.name
          @subexprs = @element_ref.subexprs
          @type = @element_ref.type
        end

        def analyse_types(local_scope)
          @pos.analyse_types local_scope
        end

        def c_code(local_scope)
          code = super
          code << @c_code
          code
        end
      end
    end
  end
end
