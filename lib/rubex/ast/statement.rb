include Rubex::DataType

module Rubex
  module AST
    module Statement
      class Base
        include Rubex::Helpers::NodeTypeMethods

        # File name and line number of statement in "file_name:lineno" format.
        attr_reader :location

        def initialize(location)
          @location = location
        end

        def statement?
          true
        end

        def ==(other)
          self.class == other.class
        end

        def generate_code(code, _local_scope)
          code.write_location @location
        end
      end
    end
  end
end
