require 'env.rb'

describe Alexandria::MashWrapper do
	before :each do
		@mash = Hashie::Mash.new(:a => 1, :b => "2")
		@wrap = Alexandria::MashWrapper.new(@mash)
	end
	
	it "delegates to the mash" do
		@wrap.should respond_to(:a)
		@wrap.a.should == 1
	end

	it "delegates JSONing to the mash" do
		@wrap.to_json.should == @mash.to_json
	end

	it "removes vanilla IDs from the JSON" do
		@mash.id = 123
		
		@mash.to_json.should match(/"id"/)
		@wrap.to_json.should_not match(/"id"/)
	end
end