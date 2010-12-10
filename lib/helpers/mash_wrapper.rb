module Alexandria
	# wraps a Hashie::Mash to remove JavaScript-killing "Snowflake" tweet ids
	class MashWrapper
		def self.delete_if_str_variant_present(h, k, v="")
			h.delete(k) if h.key?("#{k}_str")
		end
		
		def initialize(mash=Hashie::Mash.new)
			@mash = mash
			
			#protect JavaScript from dying on these too-big integers
			@mash.each_pair {|k,v| MashWrapper.delete_if_str_variant_present(@mash, k, v)}
		end
		
		def respond_to?(method)
			super.respond_to?(method) || @mash.respond_to?(method)
		end
		
		def method_missing(method, *args, &block)
			@mash.send method, *args, &block
		end
		
		def to_json(*args)
			@mash.to_json(*args).gsub(/,?"id":\d+/, "")
		end
	end
end
