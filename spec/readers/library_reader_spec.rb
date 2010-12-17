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
		Alexandria::LibraryWriter.write(opts) do |io|
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
	
	it "knows where to pull tweets from" do
		@reader.filename.should == "library_reader.tweetlib.html"
	end

	it "can override where to pull tweets from" do
		@reader.opts[:lib_file] = "My.tweetlib.html"
		@reader.filename.should == "My.tweetlib.html"
	end

	it "can override where to pull tweets from without changing the destination" do
		@reader.opts[:in_lib_file] = "My.tweetlib.html"
		@reader.filename.should == "My.tweetlib.html"
	end
	
	it "pulls in tweets" do
		Twitter.stub!(:user).and_return(Hashie::Mash.new(:id_str => "10588782"))
		
		tweets = @reader.all_tweets
		tweets.count.should == 2
	end
	
	it "doesn't care if the library isn't there to pull from" do
		File.delete(@reader.filename) rescue nil
		
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
