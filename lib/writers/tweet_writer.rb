module Alexandria
	# The public interface for all TweetWriters
	module TweetWriter
		def write(&block)
			open
			yield(self)
		ensure
			close
		end
		
		def open; end
		def close; end
	end
	
	module TweetConsumer
		def <<(tweet)
			# write out the tweet in an appropriate way
		end
	end
	
	# If you want to write to multiple places, aggregate the writers
	class TweetWriterAggregator
		include HierarchalOutputUser
	
		attr_accessor :writers, :opts
	
		def initialize(*writers)
			self.writers = writers
			self.opts = self.writers.pop if self.writers.last.respond_to?(:each_pair)
		end
	
		def write(&block)
			write_to(writers, [], &block)
		end
	
		def write_to(unstarted_writers, ios, &block)
			if unstarted_writers.empty?
				agg_io = Object.new
				def agg_io.ios; @ios; end
				def agg_io.ios=(v); @ios = v; end
				def agg_io.<<(t)
					ios.each {|io| io << t}
				end
			
				agg_io.ios = ios
				yield agg_io
			else
				w = unstarted_writers.shift
				w.write do |io|
					ios << io
					write_to(unstarted_writers, ios, &block)
				end
			end
		end
	end
end
