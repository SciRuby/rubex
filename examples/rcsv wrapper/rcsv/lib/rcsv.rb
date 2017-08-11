require 'rcsv.so'
require 'rcsv/version'

class Rcsv
  def self.p file_name
    Rcsv.parse(File.read(file_name), {})
  end
end