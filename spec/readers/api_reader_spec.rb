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

	it "fetches the tweet range it's told to" do
		Twitter.stub!(:user_timeline).and_return do |user, opts|
			opts[:max_id].should == 17
			[]
		end

		tweets = @reader.all_tweets(:user => "example", :max_id => 17)
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
	
	it "auto links hashtags" do
		mash = Hashie::Mash.new(JSON::parse(%{{"coordinates":null,"favorited":false,"created_at":"2009-09-21T18:33:06+00:00","truncated":false,"id_str":"4152265699","in_reply_to_user_id_str":null,"source_url":"http://bit.ly","source_name":"bit.ly","url":"http://twitter.com/TALlama/status/4152265699","contributors":null,"text":"#hcr Nikki White would have been far better off if only she had been a convicted bank robber. http://bit.ly/3eZanN","in_reply_to_status_id_str":null,"geo":null,"user_name":"TALlama","user":{"id_str":"10588782"},"in_reply_to_screen_name":null,"place":null}}))
		text_before = mash.text
		tweet = @reader.clean_tweet(mash)
		
		tweet.plain_text.should == text_before
		tweet.text.should == "<a href=\"http://twitter.com/search?q=%23hcr\" title=\"#hcr\" class=\"tweet-url hashtag\" rel=\"nofollow\">#hcr</a> Nikki White would have been far better off if only she had been a convicted bank robber. <a href=\"http://bit.ly/3eZanN\" rel=\"nofollow\">http://bit.ly/3eZanN</a>"
	end
end
