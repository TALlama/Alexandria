module Alexandria
	# a tweet from Twitter
	class Tweet < MashWrapper
		def initialize(mash=Hashie::Mash.new)
			mash = Twitter.status(mash) if mash.is_a?(String) or mash.is_a?(Numeric)
			mash = Hashie::Mash.new(mash) if mash.is_a?(Hash)
			super(mash)
		end
	
		def <=>(rhs)
			self.id_str <=> rhs.id_str
		end
	end
end