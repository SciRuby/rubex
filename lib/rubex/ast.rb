require_relative 'helpers'
require_relative 'ast/statement'
require_relative 'ast/expression'
Dir[File.join(File.dirname(File.dirname(__FILE__)), "rubex", "ast", "statement", "**", "*.rb" )].sort.each { |f| require f }
Dir[File.join(File.dirname(File.dirname(__FILE__)), "rubex", "ast", "expression", "**", "*.rb" )].sort.each { |f| require f }
require_relative 'ast/top_statement'
require_relative 'ast/node'
