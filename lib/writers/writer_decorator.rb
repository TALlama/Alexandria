module Alexandria
	class WriterDecorator
		attr_accessor :wrapped
		
		def initialize(wrapped)
			self.wrapped = wrapped
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
		def initialize(wrapped, key=:id_str)
			super(wrapped)
			
			@key = key
			@written_tweets_by_key = {}
		end
		
		def decorate(t)
			key = t.send(@key)
			if @written_tweets_by_key[key]
				nil
			else
				@written_tweets_by_key[key] = true
				t
			end
		end
	end
	
	class LoggingWriter < WriterDecorator
		include HierarchalOutputUser
		
		attr_accessor :hierarchal_output
		
		def initialize(wrapped, hierarchal_output, log_every=nil)
			super(wrapped)
			
			self.hierarchal_output = hierarchal_output
			@log_every = log_every || 50
			@seen = 0
		end
		
		def decorate(t)
			if (@seen % 50) == 0
				puts "Got #{@seen} tweets."
			end
			
			t
		end
	end
end