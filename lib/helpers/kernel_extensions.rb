module Kernel
	def Boolean(string, ifNotValid=:if_not_valid)
		return true if [true, 1].include?(string)
		return true if string =~ /^true|t|yes|y|on$/i
		
		return false if [false, 0].include?(string)
		return false if string.nil?
		return false if string =~ /^false|f|no|n|off$/i 
		
		return ifNotValid if ifNotValid != :if_not_valid
		raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
	end
end
