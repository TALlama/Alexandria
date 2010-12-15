module Alexandria
	# Write tweets out to a tweetlib.html file
	class LibraryWriter
		include HierarchalOutputUser
	
		def self.write(opts={}, &block)
			LibraryWriter.new(opts).write(&block)
		end
	
		def write(&block)
			open
			yield(self)
		ensure
			close
		end
	
		attr_accessor :opts
	
		def initialize(opts={})
			self.opts = opts
		end
		
		def user
			opts[:user]
		end
	
		def filename
			@opts[:out_lib_file] || @opts[:lib_file] || "#{user}.tweetlib.html"
		end

		def temp_filename
			filename.sub(/\.html$/) {".inprogress.html"}
		end
	
		def open
			FileUtils.mkdir_p(File.dirname(temp_filename))
			
			@io = File.open(temp_filename, "w+")
			@io << "<!DOCTYPE html>\n"
			@io << "<html>\n"
			@io << "  <head><title>#{user} Twitter Library</title>\n"
			@io << "    <link rel='stylesheet' href='alexandria.css' />\n"
			@io << "    <script>\n"
			@io << "      tweets = [\n"
		end
	
		def <<(t)
			@io << "        #{t.to_json},\n"
		end
	
		def close
			@io << "      ]\n"
			@io << "    </script>\n"
			@io << "    <script>\n"
			@io << "      users = #{opts[:user_cache].to_json}\n"
			@io << "    </script>\n"
			%w{
				https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.js
				alexandria.js
			}.each {|s| @io << "    <script src='#{s}'> </script>\n"}
			@io << "  </head>\n"
			@io << "  <body></body>\n"
			@io << "</html>\n"
			@io.close
		
			# and move the temp file into place
			FileUtils.cp(temp_filename, filename)
			FileUtils.rm(temp_filename)
		rescue
			eputs "Failed to write the tweetlib: #{$!.message}"
		end
	end
end
