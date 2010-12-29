require 'env.rb'

describe Alexandria::CLI do
	class Alexandria::CLI
		def wait; end
	end
	
	before :each do
		@cli = Alexandria::CLI.new "wait"
		@opts = @cli.send(:opts)
		@out = Capturer.new
		@err = Capturer.new
		@opts[:out] = Alexandria::HierarchalOutput.new(@out, @err)
	end
	
	def mock_library
		m = mock "Library"
		m.should_receive(:update)
		m
	end
	
	it "shows help if given no args" do
		@cli.parse
		
		@out.captured.should match(/Usage/i)
	end

	it "shows help when asked" do
		@cli.parse("help")
		
		@out.captured.should match(/Usage/i)
	end

	it "shows help if given a bad cmd" do
		proc {
			@cli.parse("notarealcommand")
		}.should exit_with_code(Alexandria::CLI::ERROR_CODES[:bad_cmd])
		
		@err.captured.should match(/Unknown command/i)
		@err.captured.should match(/Usage/i)
	end
	
	context "library updating" do
		it "fails if no user is given" do
			proc {
				@cli.parse *%w{update}
			}.should exit_with_code(Alexandria::CLI::ERROR_CODES[:bad_arg])
		end
		
		it "can tell a Library to update" do
			Alexandria::Library.stub!(:new).and_return do |user, opts|
				user.should == "ExampleGuy"
				opts[:out].should == @opts[:out]
				
				mock_library
			end
			@cli.parse *%w{update ExampleGuy}
		end

		it "can specify where to pull tweet from" do
			Alexandria::Library.stub!(:new).and_return do |user, opts|
				opts[:sources].should == [:lib, :archive, :notarealsource]
				
				mock_library
			end
			@cli.parse *%w{update ExampleGuy --source lib --source archive --source notarealsource}
		end
		
		it "can specify where to pull tweet from" do
			Alexandria::Library.stub!(:new).and_return do |user, opts|
				opts[:dests].should == [:lib, :json, :notarealdest]
				
				mock_library
			end
			@cli.parse *%w{update ExampleGuy --dest lib --dest json --dest notarealdest}
		end
		
		it "can specify arbitrary options" do
			Alexandria::Library.stub!(:new).and_return do |user, opts|
				opts[:key].should == "value"
				
				mock_library
			end
			@cli.parse *%w{update ExampleGuy --opt key value}
		end

		it "can ask for tweets to be refetched from the API" do
			Alexandria::Library.stub!(:new).and_return do |user, opts|
				opts[:refetch_from_api].should == true

				mock_library
			end
			@cli.parse *%w{update ExampleGuy --refetch}
		end
		
		it "fails if given bad options" do
			proc {
				@cli.parse *%w{update ExampleGuy --notarealopt}
			}.should exit_with_code(Alexandria::CLI::ERROR_CODES[:bad_arg])
		end
	end
end