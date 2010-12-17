require 'env.rb'

describe Alexandria::ArchiveReader do
	def tweet_from_html(html)
		doc = Nokogiri::HTML(html)
		node = doc.at_css('li')
		@reader.tweet_from_li(node)
	end
	
	before :each do
		@silent = Alexandria::HierarchalOutput.new(DEVNULL, DEVNULL)
		@reader = Alexandria::ArchiveReader.new(:user => "ExampleGuy", :out => @silent)
		
		Twitter.stub!(:user).and_return do |screen_name|
			Hashie::Mash.new(:screen_name => screen_name)
		end
		
		@tweet = tweet_from_html(%{
			<li class="hentry u-TALlama status" id="status_4993369766">
				<span class="status-body">
					<span class="entry-content">The Superfreakonomics guys are really, 
						really wrong about global warming, and here's why: 
						<a href="http://bit.ly/1M05fo" class="tweet-url web" rel="nofollow" target="_blank">http://bit.ly/1M05fo</a>
					</span>
					<span class="meta entry-meta">
						<a href="http://twitter.com/TALlama/status/4993369766" class="entry-date" rel="bookmark">
							<span data="{time:'Mon Oct 19 15:30:29 +0000 2009'}" 
								class="published timestamp">8:30 AM Oct 19th</span>
						</a>
						<span>from <a href="http://bit.ly" rel="nofollow">bit.ly</a></span>
					</span>
				</span>
			</li>
		})
		
		@reply = tweet_from_html(%{
			<li class="hentry u-TALlama status" id="status_5034174917">
				<span class="status-body">
					<span class="entry-content">@<a class="tweet-url username" href="/lemmo">lemmo</a> 
						that was awesome.
					</span>
					<span class="meta entry-meta">
						<a href="http://twitter.com/TALlama/status/5034174917" class="entry-date" rel="bookmark">
							<span class="published timestamp" data="{time:'Wed Oct 21 02:18:54 +0000 2009'}"
								>7:18 PM Oct 20th</span>
						</a>
						<span>from <a href="http://twitterrific.com" rel="nofollow">Twitterrific</a></span>
						<a href="http://twitter.com/lemmo/status/5034093400">in reply to lemmo</a>
					</span>
				</span>
			</li>
		})
	end
	
	it "knows the file to read from" do
		@reader.filename.should == "ExampleGuy-tweet-archive.html"
	end

	it "can override file to read from" do
		@reader.opts[:archive_file] = "MyArchive.html"
		@reader.filename.should == "MyArchive.html"
	end

	it "can override file to read from without changing file to write to" do
		@reader.opts[:in_archive_file] = "MyArchive.html"
		@reader.filename.should == "MyArchive.html"
	end
	
	it "can be parsed from 2009-style output" do
		@tweet.user_name.should == "TALlama"
		@tweet.id_str.should == "4993369766"
		@tweet.url.should == 'http://twitter.com/TALlama/status/4993369766'
		@tweet.text.should include "The Superfreakonomics guys are really"
		@tweet.created_at.should == DateTime.parse("Mon Oct 19 15:30:29 +0000 2009").to_s
		@tweet.source_name.should == 'bit.ly'
		@tweet.source_url.should == 'http://bit.ly'
		@tweet.in_reply_to_name.should == nil
		@tweet.in_reply_to_url.should == nil
	end
	
	it "can be parsed from 2009-style reply" do
		@reply.user_name.should == "TALlama"
		@reply.id_str.should == "5034174917"
		@reply.url.should == 'http://twitter.com/TALlama/status/5034174917'
		@reply.text.should include "that was awesome"
		@reply.created_at.should == DateTime.parse("Wed Oct 21 02:18:54 +0000 2009").to_s
		@reply.source_name.should == 'Twitterrific'
		@reply.source_url.should == 'http://twitterrific.com'
		@reply.in_reply_to_screen_name.should == 'lemmo'
		@reply.in_reply_to_status_id_str.should == '5034093400'
	end
	
	def parse_tweet_that_lacks_timestamp
		tweet_from_html(%{
			<li class="hentry u-TALlama status" id="status_4993369766">
				<span class="status-body">
					<span class="entry-content">The Superfreakonomics guys are really, 
						really wrong about global warming, and here's why: 
						<a href="http://bit.ly/1M05fo" class="tweet-url web" rel="nofollow" target="_blank">http://bit.ly/1M05fo</a>
					</span>
					<span class="meta entry-meta">
						<a href="http://twitter.com/TALlama/status/4993369766" class="entry-date" rel="bookmark"></a>
						<span>from <a href="http://bit.ly" rel="nofollow">bit.ly</a></span>
					</span>
				</span>
			</li>
		})
	end
	
	it "fails nicely when the tweet can't be parsed" do
		proc {parse_tweet_that_lacks_timestamp}.should raise_error(/no timestamp/i)
	end
	
	it "can grab tweets from a whole file" do
		@reader.opts[:archive_file] = spec_input_file('example-page.html')
		
		tweets = @reader.all_tweets
		tweets.count.should == 20
		tweets.select {|t| t.id_str == 8031966028}.should_not == nil
	end
	
	it "can yield tweets from a whole file" do
		@reader.opts[:archive_file] = spec_input_file('example-page.html')
		
		count = 0
		@reader.each_tweet {|t| count = count + 1}
		count.should == 20
	end
	
	it "logs errors to its output" do
		proc { 
			proc {parse_tweet_that_lacks_timestamp}.should raise_error(
				Alexandria::ParseException
			)
		}.should output_to_err(
			@reader.hierarchal_output,
			/Error parsing tweet from HTML/i
		)
	end
end
