require 'env.rb'

describe Alexandria::HierarchalOutput do
	before :each do
		@ostream, @estream = '', ''
		def @ostream.puts(*args)
			args.each {|a| self << "#{a}\n" }
		end
		def @estream.puts(*args)
			args.each {|a| self << "#{a}\n" }
		end
		
		@out = Alexandria::HierarchalOutput.new(@ostream, @estream)
	end
	
	it "can output a simple string" do
		@out.puts "Test"
		@ostream.should == "Test\n"
	end
	
	it "separates multiple strings with newlines" do
		@out.puts "I am", "awesome"
		@ostream.should == "I am\nawesome\n"
	end

	it "inserts indents" do
		@out.indent = "!"
		@out.puts "Cool"
		@ostream.should == "!Cool\n"
	end
	
	it "tracks indents" do
		@out.puts "Before"
		@out.indented "Start" do
			@out.puts "During"
		end
		@out.puts "After"
		
		@ostream.should == "Before\nStart\n\tDuring\nAfter\n"
	end
	
	it "tracks multiple indents" do
		@out.puts "Before"
		@out.indent!
		@out.puts "Level 1"
		@out.indent!
		@out.puts "Level 2"
		@out.unindent!
		@out.puts "Level 1 again"
		@out.unindent!
		@out.puts "After"
		
		@ostream.should == "Before\n\tLevel 1\n\t\tLevel 2\n\tLevel 1 again\nAfter\n"
	end
	
	it "doesn't care about unindents when not indented" do
		@out.unindent!
		@out.puts "After"
		
		@ostream.should == "After\n"
	end
end