module Rubex
  module AST
    module Expression
      class BinaryBoolean < Binary
        def analyse_types local_scope
          @left.analyse_types local_scope
          @right.analyse_types local_scope
          if type_of(@left).object? || type_of(@right).object?
            @left = @left.to_ruby_object
            @right = @right.to_ruby_object
            @type = Rubex::DataType::Boolean.new
            @has_temp = true
          else
            @type = Rubex::DataType::CBoolean.new
          end
          @subexprs << @left
          @subexprs << @right
        end
      end
    end
  end
end
