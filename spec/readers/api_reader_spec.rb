require 'env.rb'

describe Alexandria::ApiReader do
	include ExampleTweets
	
	before :each do
		@reader = Alexandria::ApiReader.new(
			:api_delay => 0,
			:out => Alexandria::HierarchalOutput.new(DEVNULL, DEVNULL)
		)
		Twitter.stub!(:user).and_return(Alexandria::User.new(:screen_name => "TALlama"))
		
		example_tweets
	end
	
	it "requires a user" do
		proc { @reader.all_tweets(:user => nil) }.should raise_error(
			Alexandria::ArgumentException,
			/provide a user/)
	end
	
	it "pulls down tweets" do
		responses = [[], @tweets]
		Twitter.stub!(:user_timeline).and_return { responses.pop }
		
		tweets = @reader.all_tweets(:user => "example")
		tweets.count.should == 2
	end

	it "pulls down tweets across multiple api hits" do
		responses = [[], @tweets[0..0], @tweets[1..1]]
		Twitter.stub!(:user_timeline).and_return { responses.pop }

		tweets = @reader.all_tweets(:user => "example")
		tweets.count.should == 2
	end

	it "fetches the pages it's told to" do
		Twitter.stub!(:user_timeline).and_return do |user, opts|
			opts[:page].should == 17
			[]
		end

		tweets = @reader.all_tweets(:user => "example", :page_range => 17..23)
	end

	it "keeps track of what tweets to ask for" do
		responses = [[], @tweets[0..0], @tweets[1..1]]
		max_ids = [@tweet.id_str, @reply.id_str, nil]
		Twitter.stub!(:user_timeline).and_return do |user, opts|
			opts[:max_id].should == max_ids.pop
			responses.pop
		end

		tweets = @reader.all_tweets(:user => "example")
		tweets.count.should == 2
	end

	it "logs errors to its output" do
		Twitter.stub!(:user_timeline).and_return { "not a valid tweet list" }
		
		proc {
			proc { @reader.all_tweets(:user => "example") }.should raise_error
		}.should output_to_err(
			@reader.hierarchal_output,
			/error getting page/i
		)
	end
end
