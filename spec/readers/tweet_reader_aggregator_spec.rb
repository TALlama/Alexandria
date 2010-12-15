require 'env.rb'

describe Alexandria::TweetReaderAggregator do
	it "runs through each wrapped reader in order" do
		reader1 = [:a, :b]
		reader2 = [:c, :d]
		
		def reader1.each_tweet(opts, &block); each(&block) end
		def reader2.each_tweet(opts, &block); each(&block) end
		
		agg = Alexandria::TweetReaderAggregator.new(reader1, reader2)
		agg.opts = {:out => Alexandria::HierarchalOutput.new(DEVNULL, DEVNULL)}
		
		tweets = agg.all_tweets
		
		tweets.count.should == 4
		tweets.should == [:a, :b, :c, :d]
	end
end