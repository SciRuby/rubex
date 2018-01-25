module Rubex
  module AST
    module Statement
      module BeginBlock
        class Rescue < Base
          attr_reader :error_klass

          def initialize(error_klass, error_obj, statements, location)
            super(statements, location)
            @error_klass = error_klass
            @error_obj = error_obj
          end

          def analyse_statement(local_scope)
            @error_klass.analyse_types local_scope
            unless @error_klass.type.ruby_constant?
              raise "Must pass an error class to raise. Location #{@location}."
            end

            @statements.each do |stmt|
              stmt.analyse_statement local_scope
            end
          end

          def generate_code(code, local_scope)
            @statements.each do |stmt|
              stmt.generate_code code, local_scope
            end
          end
        end
      end
    end
  end
end
