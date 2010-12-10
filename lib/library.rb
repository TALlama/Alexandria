require File.expand_path('../helpers/user_cache', __FILE__)
require File.expand_path('../readers/tweet_reader', __FILE__)
require File.expand_path('../readers/library_reader', __FILE__)
require File.expand_path('../readers/archive_reader', __FILE__)
require File.expand_path('../readers/api_reader', __FILE__)

module Alexandria
	# a library of a user's tweets
	class Library
		include HierarchalOutputUser
		
		attr_accessor :user, :opts
		
		def initialize(user=Hashie::Mash.new, opts={})
			self.user = user
			self.opts = opts
		end
		
		def filename
			"#{user}.tweetlib.html"
		end
		
		def reader
			source_list = opts[:sources]
			source_list = [:lib, :archive, :api] if source_list.nil? or source_list.empty?
			
			sources = source_list.collect do |source|
				case source.to_sym
				when :lib
					LibraryReader.new(opts)
				when :archive
					ArchiveReader.new(opts)
				when :api
					ApiReader.new(opts)
				else
					raise Exception.new("Unknown source type: #{source}")
				end
			end
			
			if sources.length == 1
				sources.pop
			else
				sources << opts
				TweetReaderAggregator.new(*sources)
			end
		end
		
		def writer
			dest_list = opts[:dests] || opts[:destinations]
			dest_list = [:lib] if dest_list.nil? or dest_list.empty?
			
			dests = dest_list.collect do |dest|
				case dest.to_sym
				when :lib
					LibraryWriter.new(opts)
				when :json
					JsonWriter.new(opts)
				else
					raise Exception.new("Unknown destination type: #{dest}")
				end
			end
			
			if dests.length == 1
				dests.pop
			else
				dests << opts
				TweetWriterAggregator.new(*dests)
			end
		end
		
		def update
			opts[:user] = user
			opts[:user_cache] = UserCache.new
			
			r, w = reader, writer
			
			w.write do |io|
				r.each_tweet(opts) {|t| io << t}
			end
		end
	end
end
