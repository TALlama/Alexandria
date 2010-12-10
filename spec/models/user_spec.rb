require 'env.rb'

describe Alexandria::User do
	it "can be initialized with just a username" do
		Twitter.stub!(:user).and_return do |name|
			Hashie::Mash.new(:screen_name => "TALlama")
		end
		
		@user = Alexandria::User.new("tallama")
		@user.should_not == nil
		@user.screen_name.should == "TALlama"
	end
	
	it "can be initialized with just an id" do
		Twitter.stub!(:user).and_return do |id|
			Hashie::Mash.new(:screen_name => "TALlama")
		end
		
		@user = Alexandria::User.new(1723)
		@user.should_not == nil
		@user.screen_name.should == "TALlama"
	end

	it "can be initialized with a mash" do
		Twitter.stub!(:user).and_throw(:should_not_hit_the_api)
		
		@mash = Hashie::Mash.new(:screen_name => "TALlama")

		@user = Alexandria::User.new(@mash)
		@user.should_not == nil
		@user.screen_name.should == "TALlama"
	end

	it "can be initialized with a hash" do
		Twitter.stub!(:user).and_throw(:should_not_hit_the_api)

		@user = Alexandria::User.new(:screen_name => "TALlama")
		@user.should_not == nil
		@user.screen_name.should == "TALlama"
	end
end