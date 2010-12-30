module Alexandria
	# The interface for all tweet-readers in Alexandria
	module TweetReader
		def each_tweet(options={}, &block)
			all_tweets.each(&block)
		end
		
		def all_tweets(options={})
			arr = []
			each_tweet(options) {|t| arr << t}
			arr
		end
	end
	
	# if you want to read from multiple successive sources, aggregate them
	class TweetReaderAggregator
		include TweetReader
		include HierarchalOutputUser
		
		attr_accessor :readers, :opts
		
		def initialize(*readers)
			self.readers = readers
			self.opts = self.readers.pop if self.readers.last.respond_to?(:each_pair)
		end
		
		def each_tweet(opts={})
			ix_reader = 1
			readers.each do |r|
				indented "Reading from #{r.class} (reader ##{ix_reader} of #{readers.count})" do
					r.each_tweet(opts) {|t| yield t}
				end
				ix_reader = ix_reader.succ
			end
			nil
		end
	end
end