module Alexandria
	# write tweets out as a JSON array
	class JsonWriter
		include HierarchalOutputUser
		
		attr_accessor :opts
		
		def initialize(opts={})
			self.opts = opts
		end
		
		def write
			indented "[" do
				yield self
			end
			puts "]"
		end
		
		def <<(t)
			puts t.to_json + ","
		end
	end
end
