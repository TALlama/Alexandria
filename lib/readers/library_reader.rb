module Alexandria
	# read tweets out of an Alexandria tweelib.html file
	class LibraryReader
		include TweetReader
		include HierarchalOutputUser
		include UserCacheUser
		
		attr_accessor :opts, :user
		
		def initialize(opts={})
			self.opts = opts
		end
		
		def user
			opts[:user]
		end
		
		def filename
			@opts[:in_lib_file] || @opts[:lib_file] || "#{user}.tweetlib.html"
		end
		
		def each_tweet(options={})
			raise ArgumentException.new("Must provide a user") unless user
			unless File.exists?(filename)
				puts "Skipping library file; was not at #{filename}"
				return
			end
			
			api_reader = ApiReader.new(opts)
			
			in_users_object = false
			in_tweet_list = false
			
			f = File.open(filename, "r") 
			f.each_line do |line|
				break if in_tweet_list and line.strip == "]"
				
				if in_users_object
					if line.strip == "})"
						in_users_object = false
						next
					end
					
					json = line.strip.sub(/,$/, '')
					user_cache.load_users_from_json('{' + json + '}')
				else
					in_users_object = line.strip == "jQuery.extend(users, {"
				end
				
				if in_tweet_list
					begin
						json = line.strip.sub(/,$/, '')
						hash = JSON::parse(json)
						tweet = api_reader.clean_tweet(hash)
						yield tweet
					rescue Exception => e
						pe = ParseException.new("Error parsing tweet from JSON: #{e.message}\n#{line}")
						pe.set_backtrace(e.backtrace)
						eputs pe.message
						raise pe
					end
				else
					in_tweet_list = line.strip == "tweets = ["
				end
			end
		end
	end
end
