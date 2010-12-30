module Alexandria
	class TweetArrayReader
		include TweetReader
		
		def initialize(*tweets)
			@tweets = tweets.flatten
		end
		
		def all_tweets(opts={})
			@tweets
		end
	end
end
