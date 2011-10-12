require 'date'

module Alexandria
	# pull tweets directly out of Twitter's public API
	class ApiReader
		DEFAULT_PAGE_RANGE = 0..15
		DEFAULT_PAGE_COUNT = 200
		
		include TweetReader
		include Twitter::Autolink
		include HierarchalOutputUser
		include UserCacheUser
		
		attr_accessor :opts, :api_delay
		
		def initialize(opts={})
			self.opts = opts
			self.api_delay = opts[:api_delay] || 1
		end
		
		def get_tweet(id_str)
			return nil if @rate_limit_exceeded #don't piss off the folks at Twitter
			
			mash = Twitter.status(id_str, :trim_user => true)
			sleep api_delay
			clean_tweet(mash)
		rescue => e
			@rate_limit_exceeded ||= e.is_a?(Twitter::BadRequest) and e.message =~ /rate limit exceeded/i
			nil
		end
		
		def clean_tweet(mash)
			tweet = Tweet.new(mash)
			tweet.plain_text ||= tweet.text unless tweet.autolinked
			tweet.text = auto_link(tweet.plain_text) unless tweet.autolinked
			tweet.autolinked = true
			tweet.created_at = DateTime.parse(tweet.created_at).to_s
			user_by_id_str(tweet.user.id_str)
			tweet
		end
		
		def each_tweet(options={})
			user = options[:user]
			raise ArgumentException, "Must provide a user" unless user
			page_range = options[:page_range] || DEFAULT_PAGE_RANGE
			page_range = Range.new(page_range[/^(\d+)/, 1].to_i, page_range[/(\d)+$/, 1].to_i) if page_range.is_a? String
			
			page_index = page_range ? page_range.first : 0
			
			page_range_desc = page_range ? "pages #{page_range.inspect}" : "all pages"
			puts "Getting #{page_range_desc} of #{user}'s tweets..."
			
			indented do
				found_tweets = true
				
				page_range.each do |page_index|
					break if opts[:hit_duplicate]
					break unless found_tweets
					next if page_index < 0
					
					puts "Getting page #{page_index}"
					
					begin
						indented do
							call_opts = {
								:count => options[:count] || DEFAULT_PAGE_COUNT, 
								:trim_user => true
							}
							call_opts[:since_id] = options[:since_id] if options[:since_id]
							call_opts[:max_id] = options[:max_id] if options[:max_id]
							tweets = Twitter.user_timeline("#{user}", call_opts)
							if tweets.empty?
								puts "No tweets; ending fetch"
								found_tweets = false
							else
								puts "#{tweets.size} tweets"
								tweets.sort_by(&:id_str).reverse.each do |t|
									yield clean_tweet(t) unless t.id_str == options[:max_id]
								end
								options[:max_id] = tweets.last.id_str
							end
							
							sleep api_delay
						end
					rescue Exception => e
						pe = Exception.new("Got an error getting page #{page_index}: #{e.message}")
						pe.set_backtrace(e.backtrace)
						
						eputs pe.message
						raise e
					end
				end
			end
		end
	end
end
