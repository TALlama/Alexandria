require File.expand_path('../tweet_reader', __FILE__)

module Alexandria
	class RefetchingReader
		include TweetReader
		include HierarchalOutputUser
		include UserCacheUser
		
		attr_accessor :opts, :wrapped, :tweet_fetcher
		
		def initialize(opts={}, wrapped=nil)
			self.opts = opts
			self.wrapped = wrapped
		end
		
		def tweet_fetcher
			@tweet_fetcher ||= ApiReader.new(opts)
		end
		
		def each_tweet(opts={})
			wrapped.each_tweet(opts) do |t|
				yield refetch(t)
			end
		end
		
		def refetch(tweet)
			return tweet unless should_refetch(tweet)
			
			dputs "Refetching tweet ##{tweet.id_str}"
			tweet_fetcher.get_tweet(tweet.id_str) || tweet
		end
		
		def should_refetch(tweet)
			return true if tweet.key?('autolinked') == false
			return true if tweet.autolinked? == false
			return true if tweet.text == tweet.plain_text
		end
	end
end
