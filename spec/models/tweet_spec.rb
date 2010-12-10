require 'env.rb'

describe Alexandria::Tweet do
	it "can be initialized with just an id" do
		Twitter.stub!(:status).and_return do |id|
			Hashie::Mash.new(:text => "Hello, world!")
		end
		
		@tweet = Alexandria::Tweet.new(1723)
		@tweet.should_not == nil
		@tweet.text.should == "Hello, world!"
	end

	it "can be initialized with a mash" do
		Twitter.stub!(:user).and_throw(:should_not_hit_the_api)
		
		@mash = Hashie::Mash.new(:text => "Hello, world!")

		@tweet = Alexandria::Tweet.new(@mash)
		@tweet.should_not == nil
		@tweet.text.should == "Hello, world!"
	end

	it "can be initialized with a hash" do
		Twitter.stub!(:user).and_throw(:should_not_hit_the_api)

		@tweet = Alexandria::Tweet.new(:text => "Hello, world!")
		@tweet.should_not == nil
		@tweet.text.should == "Hello, world!"
	end

	it "sorts by id" do
		@tweets = [
			Alexandria::Tweet.new(:id_str => 3),
			Alexandria::Tweet.new(:id_str => 1),
			Alexandria::Tweet.new(:id_str => 2)
		].sort
		
		@tweets[0].id_str.should == 1
		@tweets[1].id_str.should == 2
		@tweets[2].id_str.should == 3
	end
end