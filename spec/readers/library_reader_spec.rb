require 'env.rb'
require 'hashie'

describe Alexandria::LibraryReader do
	include ExampleTweets
	
	before :each do
		opts = {
			:user => File.basename(__FILE__, '_spec.rb'),
			:out => Alexandria::HierarchalOutput.new(DEVNULL, DEVNULL),
		}
		
		example_tweets
		@writer = Alexandria::LibraryWriter.new(opts)
		File.delete(@writer.filename) rescue nil
		@writer.write do |io|
			io << @tweet
			io << @reply
		end
		
		@reader = Alexandria::LibraryReader.new(opts)
	end
	
	after :each do
		File.delete(@writer.filename) rescue nil
	end
	
	it "requires a user" do
		@reader.opts[:user] = nil
		proc { @reader.all_tweets }.should raise_error(
			Alexandria::ArgumentException,
			/provide a user/)
	end
	
	it "pulls in tweets" do
		Twitter.stub!(:user).and_return(Hashie::Mash.new(:id_str => "10588782"))
		
		tweets = @reader.all_tweets
		tweets.count.should == 2
	end
	
	it "doesn't care if the library isn't there to pull from" do
		File.delete(@writer.filename) rescue nil
		
		tweets = @reader.all_tweets
		tweets.count.should == 0
	end

	it "logs errors to its output" do
		handle_tweet = proc {|t| raise "Oh no!"}
		read_tweets = proc { @reader.each_tweet &handle_tweet }
		read_tweets.should raise_error(Alexandria::ParseException, /Error parsing tweet from JSON/i)
		
		proc { 
			read_tweets.should raise_error(
				Alexandria::ParseException
			)
		}.should output_to_err(
			@reader.hierarchal_output,
			/Error parsing tweet from JSON/i
		)
	end
end
