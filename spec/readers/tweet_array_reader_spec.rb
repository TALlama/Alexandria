require 'env.rb'

describe Alexandria::TweetArrayReader do
	include ExampleTweets
	
	before :each do
		example_tweets
	end
	
	it "reads in tweets given individually to the constructor" do
		@r = Alexandria::TweetArrayReader.new(@tweet, @reply)
		tweets = @r.all_tweets
		tweets.first.should == @tweet
		tweets.last.should == @reply
	end
	
	it "reads in tweets given as an array to the constructor" do
		@r = Alexandria::TweetArrayReader.new([@tweet, @reply])
		tweets = @r.all_tweets
		tweets.first.should == @tweet
		tweets.last.should == @reply
	end
end