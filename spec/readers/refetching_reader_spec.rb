require 'env.rb'

describe Alexandria::RefetchingReader do
	include ExampleTweets
	
	before :each do
		example_tweets
		
		@fetcher = {:hit_for => [], :hit_count => 0}
		def @fetcher.get_tweet(id_str)
			self[:hit_for] << id_str
			self[:hit_count] += 1
			"fetch of tweet ##{id_str}"
		end
		
		@r = Alexandria::RefetchingReader.new
		@r.wrapped = Alexandria::TweetArrayReader.new(@tweets)
		@r.tweet_fetcher = @fetcher
	end
	
	it "fetches tweets it gets from its wrapped reader if they don't know if they're autolinked" do
		@tweet.delete('autolinked')
		@reply.delete('autolinked')
	
		tweets = @r.all_tweets
		
		@fetcher[:hit_count].should == 2
		
		tweets.length.should == 2
		tweets.first.should == "fetch of tweet #7899947810693120"
		tweets.last.should == "fetch of tweet #8023212889739265"
	end
	
	it "fetches tweets it gets from its wrapped reader if they know they're not autolinked" do
		@tweet.autolinked = false
		@reply.autolinked = false
		
		tweets = @r.all_tweets
		
		@fetcher[:hit_count].should == 2
		
		tweets.length.should == 2
		tweets.first.should == "fetch of tweet #7899947810693120"
		tweets.last.should == "fetch of tweet #8023212889739265"
	end

	it "does not fetch tweets it gets from its wrapped reader if they are autolinked" do
		@tweet.autolinked = true
		@reply.autolinked = true
		
		tweets = @r.all_tweets

		@fetcher[:hit_count].should == 0

		tweets.length.should == 2
		tweets.first.should == @tweet
		tweets.last.should == @reply
	end

	it "fetch tweets it gets from its wrapped reader if they have no plain_text" do
		@tweet.delete('plain_text')
		@reply.delete('plain_text')

		tweets = @r.all_tweets

		@fetcher[:hit_count].should == 2

		tweets.length.should == 2
		tweets.first.should == "fetch of tweet #7899947810693120"
		tweets.last.should == "fetch of tweet #8023212889739265"
	end
	
	it "fetch tweets it gets from its wrapped reader if their text and plain_text match" do
		@tweet.autolinked = true
		@reply.autolinked = true
		
		@tweet.plain_text = @tweet.text
		@reply.plain_text = @reply.text
		
		tweets = @r.all_tweets

		@fetcher[:hit_count].should == 2

		tweets.length.should == 2
		tweets.first.should == "fetch of tweet #7899947810693120"
		tweets.last.should == "fetch of tweet #8023212889739265"
	end

	it "does not fetch tweets it gets from its wrapped reader if their text and plain_text do not match" do
		@tweet.autolinked = true
		@reply.autolinked = true
		
		@tweet.plain_text = @tweet.text
		@tweet.text = '<tiny>' + @tweet.text + '</tiny>'
		@reply.plain_text = @reply.text
		@reply.text = '<tiny>' + @reply.text + '</tiny>'

		tweets = @r.all_tweets

		@fetcher[:hit_count].should == 0

		tweets.length.should == 2
		tweets.first.should == @tweet
		tweets.last.should == @reply
	end
end
