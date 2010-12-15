require 'env.rb'

describe Alexandria::LibraryWriter do
	include ExampleTweets
	
	before :each do
		@w = Alexandria::LibraryWriter.new(:user => "ExampleGuy")
		example_tweets
	end
	
	it "knows where to write" do
		@w.filename.should == "ExampleGuy.tweetlib.html"
	end

	it "knows where to stash in-progress writing" do
		@w.temp_filename.should == "ExampleGuy.tweetlib.inprogress.html"
	end
	
	it "knows where to write when that path is specified uniquely" do
		@w.opts[:out_lib_file] = "My.tweetlib.html"
		@w.filename.should == "My.tweetlib.html"
	end
	
	it "can write the file" do
		@w.opts[:out_lib_file] = File.join(Dir::tmpdir, 'unittest.tweetlib.html')
		@w.write do |io|
		end
		
		File.exists?(@w.filename).should == true
		content = File.read(@w.filename)
		content.should match(/<html/i)
	end
end