require 'env.rb'
require File.expand_path('writer_helpers.rb', File.dirname(__FILE__))

describe Alexandria::TweetWriter do
	class ConcreteTweetWriter
		include Alexandria::TweetWriter
		def <<(t); end
	end
	
	before :each do
		@w = ConcreteTweetWriter.new
	end
	
	it "is useless out of the box" do
		@w.write {|io| io << "Tweet"}
	end
end