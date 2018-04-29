module Rubex
  module AST
    module Node
      # Class for denoting a rubex file that is required from another rubex file.
      #   Takes the Object scope from the MainNode or other FileNode objects and
      #   uses that for storing any symbols that it encounters.
      class FileNode < Base
      end
    end
  end
end
