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
end