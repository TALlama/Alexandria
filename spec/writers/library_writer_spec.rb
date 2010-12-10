require 'env.rb'

describe Alexandria::LibraryWriter do
	include ExampleTweets
	
	before :each do
		@w = Alexandria::LibraryWriter.new(:user => "ExampleGuy")
		example_tweets
	end
	
	it "knows where to write" do
		@w.filename.should == "ExampleGuy.tweetlib.html"
	end

	it "knows where to stash in-progress writing" do
		@w.temp_filename.should == "ExampleGuy.tweetlib.inprogress.html"
	end
end