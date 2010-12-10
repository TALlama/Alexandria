module Alexandria
	# a Twitter user
	class User < MashWrapper
		def initialize(mash=Hashie::Mash.new)
			mash = Twitter.user(mash) if mash.is_a?(String) or mash.is_a?(Numeric)
			mash = Hashie::Mash.new(mash) if mash.is_a?(Hash)
			mash = Twitter.user(mash.id_str) unless mash.screen_name
			super(mash)
		end
		
		def to_s
			screen_name
		end
	end
end