require 'env.rb'

describe Alexandria::JsonWriter do
	before :each do
		@out = Capturer.new
		@err = Capturer.new
		@w = Alexandria::JsonWriter.new(:out => Alexandria::HierarchalOutput.new(@out, @err))
	end
	
	it "writes a JSON array" do
		@w.write do |io|
		end
		
		@out.captured.should match(/[\s+]/m)
	end
	
	it "writes to the hierarchal output" do
		@w.write do |io|
			io << {:s=>"x", :n=>1}
			io << {:s=>"y", :n=>2}
		end
		
		@out.captured.should match(/[\s+{"s":"x","n":1},\s+{"s":"y","n":2}]/m)
	end
end