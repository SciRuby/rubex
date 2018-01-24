module Rubex
  module AST
    module Expression

      class ElementRef < Base
        # FIXME: get rid of this object_ptr for good.
        attr_reader :entry, :pos, :type, :name, :object_ptr, :subexprs
        extend Forwardable
        def_delegators :@element_ref, :generate_disposal_code, :generate_evaluation_code,
        :analyse_statement, :generate_element_ref_code,
        :generate_assignment_code, :has_temp, :c_code, :allocate_temp,
        :allocate_temps, :release_temp, :release_temps, :to_ruby_object,
        :from_ruby_object

        def initialize(name, pos)
          @name = name
          @pos = pos
          @subexprs = []
        end

        def analyse_types(local_scope, struct_scope = nil)
          @entry = struct_scope.nil? ? local_scope.find(@name) : struct_scope[@name]
          @type = @entry.type.object? ? @entry.type : @entry.type.type
          @element_ref = proper_analysed_type
          @element_ref.analyse_types local_scope
          super(local_scope)
        end

        private

        def proper_analysed_type
          if ruby_object_c_array?
            @object_ptr = true
            CVarElementRef.new(self)
          else
            if ruby_array?
              RubyArrayElementRef.new(self)
            elsif ruby_hash?
              RubyHashElementRef.new(self)
            elsif generic_ruby_object?
              RubyObjectElementRef.new(self)
            else
              CVarElementRef.new(self)
            end
          end
        end

        def ruby_array?
          @type.ruby_array?
        end

        def ruby_hash?
          @type.ruby_hash?
        end

        def generic_ruby_object?
          @type.object?
        end

        def ruby_object_c_array?
          @entry.type.cptr? && @entry.type.type.object?
        end
      end # class ElementRef

    end
  end
end
