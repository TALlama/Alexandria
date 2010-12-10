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

	it "has a writer to write out tweets" do
		@w = @lib.writer
		@w.should_not == nil
		@w.should respond_to(:write)
	end

	it "will only write to the tweetlib when told to do so" do
		@lib.opts[:dests] = [:lib]
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
end