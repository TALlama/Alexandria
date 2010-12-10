require File.join(File.dirname(File.dirname(__FILE__)), 'alexandria.rb')

unless defined? DEVNULL
	module ::Twitter
		module Connection
			def connection(*args, &block)
				throw :api_access_not_allowed
			end
		end
	end
	
	PROJECT_DIR = File.dirname(File.dirname(__FILE__))
	def spec_input_file(name) File.join(PROJECT_DIR, 'spec_input', name) end
	def spec_output_file(name) File.join(PROJECT_DIR, 'spec_output', name) end

	DEVNULL = Object.new
	def DEVNULL.puts(*args); end
	def DEVNULL.<<(*args); end
	
	class Capturer
		attr_accessor :captured
		
		def puts(*args)
			self.captured ||= ''
			self.captured << args.join("\n")
			self.captured << "\n"
		end
		
		def <<(*args)
			puts *args
		end
	end
	
	module Net
		class FakePageResult
			def self.success
				FakePageResult.new(
					Net::HTTPSuccess, 
					File.read(spec_input_file('example-page.html')))
			end
			def self.failure
				FakePageResult.new(
					Net::HTTPClientError, 
					'Oh no!',
					'Failure',
					400)
			end
			
			attr_accessor :isa, :body, :message, :code
			
			def initialize(isa, body, message = 'OK', code = 200)
				self.isa = isa
				self.body = body
				self.message = message
				self.code = code
			end
			
			def ==(rhs)
				super == rhs || self.isa == rhs
			end
		end
	end
	
	module ExitCodeMatchers
		RSpec::Matchers.define :exit_with_code do |code|
			actual = nil
			match do |block|
				begin
					block.call
				rescue SystemExit => e
					actual = e.status
				end
				actual and actual == code
			end
			failure_message_for_should do |block|
				"expected block to call exit(#{code}) but exit" +
					(actual.nil? ? " not called" : "(#{actual}) was called")
			end
			failure_message_for_should_not do |block|
				"expected block not to call exit(#{code})"
			end
			description do
				"expect block to call exit(#{code})"
			end		 
		end	 
	end
	
	module HierarchalOutputMatchers
		RSpec::Matchers.define :output_to_err do |hierarchal_output, pattern|
			cap = Capturer.new
			hierarchal_output.err = cap
			
			match do |block|
				block.call
			
				cap.captured =~ pattern
			end
			failure_message_for_should do |block|
				"expected block to output #{pattern.inspect} to err, but got:\n\"#{cap.captured}\""
			end
			failure_message_for_should_not do |block|
				"did not expected block to output #{pattern.inspect} to err, but got:\n\"#{cap.captured}\""
			end
			description do
				"expect block to output #{pattern}"
			end
		end
	end

	RSpec.configure do |config|
		config.include(ExitCodeMatchers)
		config.include(HierarchalOutputMatchers)
	end
	
	module ExampleTweets
		def example_tweets
			{:tweet => @tweet, :reply => @reply} if @tweet and @reply
			
			@tweets = JSON::parse(%{[
				{"truncated":false,"created_at":"Thu Nov 25 20:54:28 +0000 2010","geo":null,
				 "favorited":false,"source":"<a href=\\"http://twitterrific.com\\" rel=\\"nofollow\\">Twitterrific</a>",
				 "in_reply_to_status_id_str":null,"id_str":"7899947810693120","contributors":null,"coordinates":null,
				 "in_reply_to_screen_name":null,"in_reply_to_user_id_str":null,
				 "entities":{"urls":[],"hashtags":[{"indices":[58,101],"text":"omigodyoudonthaverockswingsgogetitrightnow"}],"user_mentions":[]},
				 "place":null,"user":{"id_str":"10588782"},
				 "retweet_count":null,"retweeted":false,
				 "text":"How is it that Paul Anka hasn't done a Rock Swings 2 yet? #omigodyoudonthaverockswingsgogetitrightnow"}
				,
				{"truncated":false,"created_at":"Fri Nov 26 05:04:17 +0000 2010","geo":null,
				 "favorited":false,"source":"<a href=\\"http://twitterrific.com\\" rel=\\"nofollow\\">Twitterrific</a>",
				 "in_reply_to_status_id_str":"8020197273239552","id_str":"8023212889739265","contributors":null,
				 "coordinates":null,"in_reply_to_screen_name":"JssSandals","in_reply_to_user_id_str":"15693316",
				 "entities":{"urls":[],"hashtags":[],"user_mentions":[{"indices":[0,11],"id_str":"15693316",
				 "name":"Ben, Leader of Men","screen_name":"JssSandals"}]},"place":null,"user":{"id_str":"10588782"},
				 "retweet_count":null,"retweeted":false,
				 "text":"@JssSandals but tomorrow's family feast exists in a time warp where it is still Thanksgiving, so no Christmas music there."}
			]}).collect {|h| Hashie::Mash.new(h)}
			@tweet = @tweets[0]
			@reply = @tweets[1]
		
			@tweet.should_not == nil
			@reply.should_not == nil
			
			{:tweet => @tweet, :reply => @reply}
		end
		
		def example_tweet
			@tweet || example_tweets[:tweet]
		end
		
		def example_reply
			@tweet || example_tweets[:tweet]
		end
	end
end