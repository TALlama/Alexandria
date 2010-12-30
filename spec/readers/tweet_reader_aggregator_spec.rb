require 'env.rb'

describe Alexandria::TweetReaderAggregator do
	it "runs through each wrapped reader in order" do
		reader1 = Alexandria::TweetArrayReader.new(:a, :b)
		reader2 = Alexandria::TweetArrayReader.new(:c, :d)
		
		agg = Alexandria::TweetReaderAggregator.new(reader1, reader2)
		agg.opts = {:out => Alexandria::HierarchalOutput.new(DEVNULL, DEVNULL)}
		
		tweets = agg.all_tweets
		
		tweets.count.should == 4
		tweets.should == [:a, :b, :c, :d]
	end
end
