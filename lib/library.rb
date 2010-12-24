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
		
		def reader
			return @reader if @reader
			
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
			
			@reader = if sources.length == 1
				sources.pop
			else
				sources << opts
				TweetReaderAggregator.new(*sources)
			end
		end
		
		def writer
			return @writer if @writer
			
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
			
			actual_writer = if dests.length == 1
				dests.pop
			else
				dests << opts
				TweetWriterAggregator.new(*dests)
			end
			
			actual_writer = UniqueWriter.new(actual_writer) unless opts[:avoid_duplicates] == false
			actual_writer = LoggingWriter.new(actual_writer, hierarchal_output, opts[:log_every] || 50) unless opts[:log_every] == 0
			@writer = actual_writer
		end
		
		def writer_of_type(type)
			w = writer
			while w and !w.is_a?(type)
				w = w.wrapped
			end
			w
		end
		
		def hit_duplicates?
			writer_of_type(UniqueWriter).hit_duplicates?
		end
		
		def duplicated_keys
			writer_of_type(UniqueWriter).duplicated_keys
		end

		def out_filename
			writer_of_type(LibraryWriter).filename rescue nil
		end
		
		def update
			opts[:user] = user
			opts[:user_cache] = UserCache.new(opts)
			
			r, w = reader, writer
			
			w.write do |io|
				r.each_tweet(opts) do |t|
					io << t
				end	
				
				if hit_duplicates?
					w.puts "Duplicate tweet; done reading."
				end
			end
		end
	end
end
