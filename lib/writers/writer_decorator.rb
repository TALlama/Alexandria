module Alexandria
	class WriterDecorator
		attr_accessor :wrapped
		
		def initialize(wrapped)
			self.wrapped = wrapped
		end
		
		def opts
			wrapped.respond_to?(:opts) ? wrapped.opts : {}
		end
		
		def write
			will_start_write
			wrapped.write do |io|
				did_start_write(io)
				io_wrapper = IOWrapper.new
				io_wrapper.writer_decorator = self
				io_wrapper.wrapped_io = io
				
				yield(io_wrapper)
				will_finish_write(io)
			end
			did_finish_write
		end
		
		def decorate(t)
			t
		end
		
		def will_start_write; end
		def did_start_write(io); end
		def will_finish_write(io); end
		def did_finish_write; end
		
		class IOWrapper
			attr_accessor :writer_decorator, :wrapped_io
			
			def <<(t)
				t = writer_decorator.decorate(t)
				wrapped_io << t unless t.nil?
				t
			end
		end
	end
	
	class UniqueWriter < WriterDecorator
		include HierarchalOutputUser
		
		attr_reader :duplicated_keys
		
		def initialize(wrapped, key=:id_str)
			super(wrapped)
			
			@key = key
			@written_tweets_by_key = {}
			@duplicated_keys = []
		end
		
		def decorate(t)
			key = t.send(@key)
			if @written_tweets_by_key[key]
				@duplicated_keys << key
				opts[:hit_duplicates] = true
				nil
			else
				@written_tweets_by_key[key] = true
				t
			end
		end
		
		def hit_duplicates?
			!duplicated_keys.empty?
		end
	end
	
	class LoggingWriter < WriterDecorator
		include HierarchalOutputUser
		
		def initialize(wrapped, hierarchal_output, log_every=nil)
			super(wrapped)
			
			@log_every = log_every || 100
			@seen = 0
		end
		
		def decorate(t)
			@seen = @seen + 1
			
			if (@seen % @log_every) == 0
				puts "Total tweets: #{@seen}"
			end
			
			t
		end
		
		def did_finish_write
			puts "Final tweet count: #{@seen}"
		end
	end
end