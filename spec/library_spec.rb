require 'env.rb'

describe Alexandria::Library do
	include ExampleTweets
	
	before :each do
		@lib = Alexandria::Library.new("ExampleGuy")
		@lib.opts[:lib_file] = spec_output_file("ExampleGuy.tweetlib.html")
		@lib.opts[:api_delay] = 0
		@lib.opts[:out] = Alexandria::HierarchalOutput.new(DEVNULL, DEVNULL)
		example_tweets
	end
	
	it "has a reader to read in tweets" do
		@r = @lib.reader
		@r.should_not == nil
		@r.should be_an_instance_of(Alexandria::TweetReaderAggregator)
	end

	{:lib => Alexandria::LibraryReader,
		:archive => Alexandria::ArchiveReader,
		:api => Alexandria::ApiReader}.each_pair do |source, klass|
		it "will read only from #{source} if told to" do
			@lib.opts[:sources] = [source]
			@r = @lib.reader
			@r.should_not == nil
			@r.should be_an_instance_of(klass)
		end
	end
	
	it "complains if told to pull from a source it doesn't know" do
		@lib.opts[:sources] = [:not_a_real_source]
		proc { @r = @lib.reader }.should raise_error(
			/unknown source/i
		)
	end

	it "has a writer to write out tweets" do
		@w = @lib.writer
		@w.should_not == nil
		@w.should respond_to(:write)
	end

	it "outputs to a lib by default" do
		@w = @lib.writer
		@w.should_not == nil
		
		while @w.respond_to? :wrapped
			@w = @w.wrapped
		end
		
		@w.should be_a(Alexandria::LibraryWriter)
	end
	
	{:lib => Alexandria::LibraryWriter,
		:json => Alexandria::JsonWriter}.each_pair do |destination, klass|
		it "outputs to a #{destination} if told to" do
			@lib.opts[:dests] = [destination]
			@w = @lib.writer
			@w.should_not == nil
		
			while @w.respond_to? :wrapped
				@w = @w.wrapped
			end
		
			@w.should be_a(klass)
		end
	end
	
	it "outputs to multiple locations if needed" do
		@lib.opts[:dests] = [:lib, :json]
		@w = @lib.writer
		@w.should_not == nil
		
		while @w.respond_to? :wrapped
			@w = @w.wrapped
		end
		
		@w.should be_a(Alexandria::TweetWriterAggregator)
	end
	
	it "complains if told to push to a destination it doesn't know" do
		@lib.opts[:dests] = [:not_a_real_destintion]
		proc { @r = @lib.writer }.should raise_error(
			/unknown destination/i
		)
	end

	it "logs incoming tweet counts by default" do
		@lib.opts.merge!(
			:dests => [:lib],
			:avoid_duplicates => false
		)
		@w = @lib.writer
		@w.should_not == nil
		@w.should be_a(Alexandria::LoggingWriter)
		@w.wrapped.should be_a(Alexandria::LibraryWriter)
	end
	
	it "avoids writing duplicates by default" do
		@lib.opts.merge!(
			:dests => [:lib],
			:log_every => 0
		)
		@w = @lib.writer
		@w.should_not == nil
		@w.should be_a(Alexandria::UniqueWriter)
		@w.wrapped.should be_a(Alexandria::LibraryWriter)
	end

	it "will only write to the tweetlib when told to do so" do
		@lib.opts.merge!(
			:dests => [:lib],
			:log_every => 0,
			:avoid_duplicates => false
		)
		@w = @lib.writer
		@w.should_not == nil
		@w.should be_a(Alexandria::LibraryWriter)
	end

	it "can update a library" do
		responses = [[], @tweets[0..0], @tweets[1..1]]
		Twitter.stub!(:user_timeline).and_return { responses.pop }
		Twitter.stub!(:user).and_return(Alexandria::User.new(
			:id_str => "10588782", 
			:screen_name => "TALlama"))
	
		@lib.opts[:sources] = [:api]
	
		@lib.update
	end

	it "will stop pulling from the API when it hits tweets already pulled from the lib" do
		# write out a library containing the tweet
		Alexandria::LibraryWriter.write(@lib.opts.merge({
			:lib_file => spec_input_file('example.tweetlib.html')
		})) do |io|
			io << @tweet
		end
		
		# first get the reply, then the tweet, then die if there's a third pull
		responses = [:if_this_is_pulled_we_die, @tweets[0..0], @tweets[1..1]]
		Twitter.stub!(:user_timeline).and_return { responses.pop }
		Twitter.stub!(:user).and_return(Alexandria::User.new(
			:id_str => "10588782", 
			:screen_name => "TALlama"))

		@lib.opts[:sources] = [:lib, :api]
		@lib.opts[:in_lib_file] = spec_input_file('example.tweetlib.html')

		File.delete(@lib.out_filename) rescue nil
		@lib.update
		
		output = File.read(@lib.out_filename)
		output.should match(@tweet.id_str)
		output.should match(@reply.id_str)
	end
end