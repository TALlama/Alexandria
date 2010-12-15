require File.expand_path('../../helpers/user_cache', __FILE__)

module Alexandria
	# Parse 2009-style pre-#newtwitter HTML pages scraped from twitter.com
	class ArchiveReader
		include TweetReader
		include HierarchalOutputUser
		include UserCacheUser
		
		attr_accessor :opts
		
		def initialize(opts={})
			self.opts = opts
		end
		
		def user
			opts[:user]
		end
		
		def filename
			@opts[:archive_file] || "#{user}-tweet-archive.html"
		end
		
		def each_tweet(options={}, &block)
			return unless File.exists?(filename)
			
			html = File.read(filename)
			return unless html.include?("xhtml1-strict.dtd")
			
			tweets_from_html(html, &block)
		end
		
		def all_tweets(options={})
			each_tweet(options)
		end
		
		def tweets_from_html(html)
			doc = Nokogiri::HTML(html)
			
			all_tweets = []
			doc.css('li.status').each do |li|
				tweet = tweet_from_li(li)
				
				if block_given?
					yield tweet
				else
					all_tweets << tweet
				end
			end
			
			all_tweets
		end
		
		def tweet_from_li(li)
			# <li class='status' id='status_449576432'>
			# 	<span class='entry-content'>Getting two ADC emails from Apple, because I'm registered twice.  I really should fix that sometime.</span>
			# 	<span class='entry-meta'>
			# 		<a href='http://twitter.com//status/449576432' class='entry-date' rel='bookmark'><span 
			# 			data="{time: '2007-11-27T23:22:54+00:00'}" class='timestamp published'>16:22:54 on 11/27/07</span></a>
			# 		<span class='entry-client'>from <a href='http://twitterrific.com'>Twitterrific</a></span>
			# 		
			# 	</span>
			# </li>
			#
			# <li class='status' id='status_7485364251'>
			# 	<span class='entry-content'>@<a href="http://twitter.com/lemmo" class="tweet-url username">lemmo</a> You celebrate the anniversary of your bris? That's weird.</span>
			# 	<span class='entry-meta'>
			# 		<a href='http://twitter.com//status/7485364251' class='entry-date' rel='bookmark'><span 
			# 			data="{time: '2010-01-07T17:19:28+00:00'}" class='timestamp published'>10:19:28 on 01/07/10</span></a>
			# 		<span class='entry-client'>from <a href='http://twitterrific.com'>Twitterrific</a></span>
			# 		
			# <a href='http://twitter.com/lemmo/status/7480726714' class='in-reply-to'>in reply to lemmo</a>
		  # 
			# 	</span>
			# </li>
			#
			# {"truncated":false,"created_at":"Thu Nov 25 20:54:28 +0000 2010","geo":null,
			#  "favorited":false,"source":"<a href=\"http://twitterrific.com\" rel=\"nofollow\">Twitterrific</a>",
			#  "in_reply_to_status_id_str":null,"id_str":"7899947810693120","contributors":null,"coordinates":null,
			#  "in_reply_to_screen_name":null,"in_reply_to_user_id_str":null,
			#  "place":null,"user":{"id_str":"10588782"},
			#  "retweet_count":null,"retweeted":false,
			#  "text":"How is it that Paul Anka hasn't done a Rock Swings 2 yet? #omigodyoudonthaverockswingsgogetitrightnow"}
			#
			# {"truncated":false,"created_at":"Fri Nov 26 05:04:17 +0000 2010","geo":null,
			#  "favorited":false,"source":"<a href=\"http://twitterrific.com\" rel=\"nofollow\">Twitterrific</a>",
			#  "in_reply_to_status_id_str":"8020197273239552","id_str":"8023212889739265","contributors":null,
			#  "coordinates":null,"in_reply_to_screen_name":"JssSandals","in_reply_to_user_id_str":"15693316",
			#  "place":null,"user":{"id_str":"10588782"},"retweet_count":null,"retweeted":false,
			#  "text":"@JssSandals but tomorrow's family feast exists in a time warp where it is still Thanksgiving, so no Christmas music there."}
			id_str = li["id"][/status_(\d+)/, 1]
			if id_str
				@api_reader ||= ApiReader.new(opts)
				tweet = @api_reader.get_tweet(id_str)
				return tweet if tweet
			end
			
			
			tweet = Hashie::Mash.new({
				# we can get this stuff
				:created_at => created_at_from_li(li).to_s,
				:id_str => id_str,
				:text => li.at_css("span.entry-content").inner_html,
				:in_reply_to_screen_name => li.to_s[/in reply to (\w+)/, 1],
				:in_reply_to_status_id_str => li.to_s[/status\/(\d+)">in reply to/, 1],
				
				# and we add this stuff
				:user_name => li["class"][/u-(\w+)/, 1] || @opts[:user],
				
				# but we can't get this from the html we saved before
				:truncated => false, :geo => nil, :favorited => false,
				:contributors => nil, :coordinates => nil, :place => nil,
				
				# we could get this, but we probably don't need to
				:in_reply_to_user_id_str => nil,
			})
			
			# and this stuff is easier to get procedurally
			tweet.url = "http://twitter.com/#{tweet.user_name}/status/#{tweet.id_str}"
			
			source_node = li.at_css("span.meta span a") || li.at_css("span.entry-meta span a")
			tweet.source = source_node.to_s
			tweet.source_name = source_node.inner_html
			tweet.source_url = source_node["href"]
			
			tweet.user = {"id_str" => user_by_screen_name(tweet.user_name).id_str}
			
			Tweet.new(tweet)
		rescue Exception => e
			pe = ParseException.new("Error parsing tweet from HTML: #{e.message}\n-- Tweet HTML:\n#{li}\n--")
			pe.set_backtrace(e.backtrace)
			eputs pe.message
			raise pe
		end
		
		def created_at_from_li(li)
			timestamp_span = li.at_css('a.entry-date span.timestamp')
			raise Exception.new("No timestamp: #{li}") unless timestamp_span
			data_attr = timestamp_span['data']
			raise Exception.new("No timestamp data: #{li}") unless data_attr
			timestamp_value = data_attr[/time: *'(.*)'/, 1]
			raise Exception.new("Bad timestamp format: #{li}") unless timestamp_value
			DateTime.parse(timestamp_value)
		end
	end
end