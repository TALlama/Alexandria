module Alexandria
	# caches users found so you don't hit the API over and over finding the same guy
	class UserCache
		attr_accessor :users_by_id_str, :users_by_screen_name
	
		def initialize
			self.users_by_id_str = {}
			self.users_by_screen_name = {}
		end
	
		def users
			users_by_id_str.values
		end
	
		def to_json(*args, &block)
			clean_list = []
			users_by_id_str.each_pair do |uid, u|
				clean_list << %{"#{uid}": #{u.to_json}}
			end
			"{\n      " + clean_list.join(",\n      ") + "\n    }"
		end
	
		def find_user(identifier)
			register_user(User.new(Twitter.user(identifier)))
		rescue
			e = Exception.new("Error getting user '#{identifier}': #{$!.message}")
			e.set_backtrace($!.backtrace)
			raise e
		end
	
		def register_user(user)
			users_by_id_str[user.id_str] = user
			users_by_screen_name[user.screen_name] = user
			user
		end
	
		def by_id_str(uid)
			return users_by_id_str[uid] if users_by_id_str[uid]
		
			find_user(uid.to_i)
		end

		def by_screen_name(screen_name)
			return users_by_screen_name[screen_name] if users_by_screen_name[screen_name]

			find_user(screen_name)
		end
	end

	module UserCacheUser
		def user_cache
			opts[:user_cache] ||= UserCache.new
		end
	
		def user_by_id_str(id_str)
			user_cache.by_id_str(id_str)
		end
	
		def user_by_screen_name(screen_name)
			user_cache.by_screen_name(screen_name)
		end
	end
end
