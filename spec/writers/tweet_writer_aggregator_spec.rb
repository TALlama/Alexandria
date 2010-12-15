require 'env.rb'
require File.expand_path('writer_helpers.rb', File.dirname(__FILE__))

describe Alexandria::TweetWriterAggregator do
	before :each do
		@cap1 = CountingWriter.new
		@cap2 = CountingWriter.new
		@agg = Alexandria::TweetWriterAggregator.new(@cap1, @cap2)
	end
	
	it "Should send each tweet to the aggregated writers" do
		@agg.write do |io| 
			io << "This is a tweet"
			io << "This is a reply"
		end
		
		@cap1.count.should == 2
		@cap2.count.should == 2
	end
	
	it "Should start the write block before it enters the write block given" do
		write_block_hit = false
		
		@agg.write do |io| 
			write_block_hit = true
			@cap1.write_started.should == true
			@cap2.write_started.should == true
		end
		
		write_block_hit.should == true
	end

	it "Should end the write block before it ends the write block given" do
		@agg.write do |io| end
		
		@cap1.write_ended.should == true
		@cap2.write_ended.should == true
	end
end
