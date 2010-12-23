require 'env.rb'

describe Kernel, "Extensions" do
	["true", "t", "TRUE", "YES", "y", "on", 1].each do |string|
		it "can convert #{string.inspect} to true" do
			Boolean(string).should == true
		end
	end
	
	["false", "f", "FALSE", "NO", "n", "off", 0].each do |string|
		it "can convert #{string.inspect} to false" do
			Boolean(string).should == false
		end
	end
end
