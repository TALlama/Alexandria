require 'env.rb'

describe Alexandria::TweetWriterAggregator do
	class Counter
		attr_accessor :write_started, :write_ended, :count
		
		def write
			self.write_started = true
			self.count = 0
			yield self
			self.write_ended = true
		end
		
		def <<(t)
			self.count = self.count + 1
		end
	end
	
	before :each do
		@cap1 = Counter.new
		@cap2 = Counter.new
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
