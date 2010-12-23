require 'env.rb'

describe Alexandria::UserCache do
	before :each do
		@uc = Alexandria::UserCache.new
	end
	
	def stub_user_find(hash={})
		hash = {
			:id_str => "123",
			:screen_name => "ExampleGuy"
		}.merge hash
		Twitter.stub!(:user).and_return(Hashie::Mash.new(hash))
	end
	
	def error_on_find
		Twitter.stub!(:user).and_throw(:should_not_hit_api)
	end
	
	it "starts with no users" do
		@uc.users.should be_empty
	end
	
	it "can find users directly, bypassing the cache" do
		stub_user_find

		user = @uc.find_user("123")
		
		@uc.users.should include(user)
	end
	
	it "can find users by id_str " do
		stub_user_find

		user = @uc.by_id_str("123")
		
		@uc.users.should include(user)
	end

	it "caches on id_str" do
		stub_user_find
		fresh = @uc.by_id_str("123")
		error_on_find
		cached = @uc.by_id_str("123")
		
		fresh.object_id.should === cached.object_id
	end
	
	it "can find users by screen_name " do
		stub_user_find

		user = @uc.by_screen_name("ExampleGuy")
		
		@uc.users.should include(user)
	end
	
	it "caches on screen_name" do
		stub_user_find
		fresh = @uc.by_screen_name("ExampleGuy")
		error_on_find
		cached = @uc.by_screen_name("ExampleGuy")
		
		fresh.object_id.should === cached.object_id
	end

	it "caches on screen_name when gotten by id_str" do
		stub_user_find
		fresh = @uc.by_id_str("123")
		error_on_find
		cached = @uc.by_screen_name("ExampleGuy")

		fresh.object_id.should === cached.object_id
	end
	
	it "caches on id_str when gotten by screen_name" do
		stub_user_find
		fresh = @uc.by_screen_name("ExampleGuy")
		error_on_find
		cached = @uc.by_id_str("123")

		fresh.object_id.should === cached.object_id
	end
	
	it "can convert itself to JSON" do
		stub_user_find
		user = @uc.by_screen_name("ExampleGuy")
		
		json = @uc.to_json
		json.should include(user.to_json) #should include the found users
		JSON::parse(json) # should be valid JSON
	end
	
	it "fails if no API access is allowed it" do
		@uc.opts[:no_api] = true
		proc {@uc.by_screen_name("ExampleGuy")}.should raise_error(
			Exception,
			/no api access allowed/i)
	end
	
	it "can load users from a JSON file" do
		@uc.load_users_from_file(spec_input_file("users.json"))
		@uc.by_id_str("10588782").id_str.should == "10588782"
	end

	it "can load users from a JSON string" do
		json = File.read(spec_input_file("users.json"))
		@uc.load_users_from_json(json)
		@uc.by_id_str("10588782").id_str.should == "10588782"
	end
end