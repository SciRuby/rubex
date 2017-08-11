require 'spec_helper'

describe "Rubex wrapper over libcsv" do
  context "Rcsv" do
    it ".p" do
      expect(Rcsv.p("spec/rcsv.csv")).to eq(
        [
          ["Name", "age", "sex"], 
          ["Sameer", "24", "M"], 
          ["Ameya", "23", "M"], 
          ["Neeraja", "23", "F"], 
          ["Shounak", "24", "M"]
        ]
      )
    end
  end
end