require File.expand_path('../helpers/hierarchal_output', __FILE__)
require File.expand_path('../library', __FILE__)

module Alexandria
	class CLI
		ERROR_CODES = {
			:bad_cmd => 1,
			:bad_arg => 2
		}
		
		def initialize(*args)
			self.opts = {:out => HierarchalOutput.new}
			
			cmd = args.first || "help"
			
			if public_methods.include? cmd.to_sym
				send_args = [cmd, args[1..args.length]].flatten
				send *send_args
			else
				fail "Unknown command: #{cmd}", :bad_cmd
			end
		end
		
		def help(*args)
			bn = File.basename($0)
			stream = args.first || hierarchal_output.out
			
			stream.puts "Usage: #{bn} <cmd> [options]"
			stream.puts "Commands:"
			stream.puts "	#{bn} help"
			stream.puts "		This help"
			stream.puts ""
			stream.puts "	#{bn} update <username> [options]"
			stream.puts "		Update the tweet library for <username>"
			stream.puts "		Options:"
			stream.puts "			--source <lib|archive|api>"
			stream.puts "				pull only from the sources given. Specify multiple sources with multiple args."
			stream.puts "			--dest <lib|json>"
			stream.puts "				output tweets to the destinations given. Specify multiple destinations with multiple args."
			stream.puts "			--opt <optname> <optvalue>"
			stream.puts "				pass <optname>=<optvalue> to all readers and writers."
			stream.puts ""
			exit args.last.to_i rescue exit 0
		end
		
		def update(*option_list)
			user = option_list.shift
			unless user
				fail "Must provide a user when updating.", :bad_arg
			end
			
			# parse out the options for updating
			options = {
				:sources => [],
				:dests => []
			}
			until option_list.empty? do
				opt = option_list.shift
				case opt
				when "--source" then
					options[:sources] << option_list.shift
				when "--dest" then
					options[:dests] << option_list.shift
				when "--opt" then
					options[option_list.shift.to_sym] = option_list.shift
				else
					fail "Unknown update option: #{opt}", :bad_arg
				end
			end
			
			indented "Updating #{user}'s tweet library..." do
				lib = Library.new(user, options)
				lib.update
			end
		end

		private

		include HierarchalOutputUser

		attr_accessor :opts

		def fail(msg, error_code)
			eputs msg, ''
			help hierarchal_output.err, ERROR_CODES[error_code] || error_code
		end
	end
end
