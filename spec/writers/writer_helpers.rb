class CountingWriter
	attr_accessor :write_started, :write_ended, :count
	
	def write
		self.write_started = true
		self.count = 0
		yield self
		self.write_ended = true
	end
	
	def <<(t)
		self.count = self.count + 1
	end
end
