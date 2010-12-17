require 'env.rb'
require File.expand_path('writer_helpers.rb', File.dirname(__FILE__))

describe Alexandria::WriterDecorator do
	before :each do
		@w = Alexandria::WriterDecorator.new(CountingWriter.new)
	end
	
	it "passes everything through by default" do
		@w.write do |io|
			io << Alexandria::Tweet.new(:id_str => "123")
			io << Alexandria::Tweet.new(:id_str => "123")
		end
		
		@w.wrapped.count.should == 2
	end
end

describe Alexandria::UniqueWriter do
	before :each do
		@w = Alexandria::UniqueWriter.new(CountingWriter.new)
	end
	
	it "will not write the same tweet multiple times" do
		@w.write do |io|
			io << Alexandria::Tweet.new(:id_str => "123")
			io << Alexandria::Tweet.new(:id_str => "123")
		end
		
		@w.wrapped.count.should == 1
	end
	
	it "will tell you if a tweet has been duplicated" do
		@w.write do |io|
			io << Alexandria::Tweet.new(:id_str => "123")
			io << Alexandria::Tweet.new(:id_str => "123")
		end
		
		@w.duplicated_keys.should include("123")
	end
end