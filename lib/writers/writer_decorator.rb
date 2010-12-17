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
			wrapped.write do |io|
				io_wrapper = IOWrapper.new
				io_wrapper.writer_decorator = self
				io_wrapper.wrapped_io = io
				
				yield(io_wrapper)
			end
		end
		
		def decorate(t)
			t
		end
		
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
			
			@log_every = log_every || 50
			@seen = 0
		end
		
		def decorate(t)
			@seen = @seen + 1
			
			if (@seen % @log_every) == 0
				puts "Total tweets: #{@seen}"
			end
			
			t
		end
	end
end