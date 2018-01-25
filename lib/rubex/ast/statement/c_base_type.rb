module Rubex
  module AST
    module Statement
      class CBaseType < Base
        attr_reader :type, :name, :value

        def initialize(type, name, value = nil)
          @type = type
          @name = name
          @value = value
        end

        def ==(other)
          self.class == other.class &&
            type == other.class  &&
            name == other.name   &&
            value == other.value
        end

        def analyse_statement(_local_scope)
          @type = Rubex::Helpers.determine_dtype @type
        end
      end
    end
  end
end
