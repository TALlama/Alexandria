module Alexandria
	# makes outputing hierarchal information (like progress checklists, xml, json) easier
	class HierarchalOutput
		attr_accessor :out, :err, :indent
	
		def initialize(out=STDOUT, err=STDERR)
			self.out = out
			self.err = err
			self.indent = ''
		end
	
		def indent!
			self.indent = "\t#{indent}"
		end
	
		def unindent!
			self.indent = self.indent.sub(/./, '')
		end
	
		def indented(msg=nil)
			self.puts(msg) unless msg.nil?
			indent!
			yield if block_given?
			unindent!
		end
	
		def puts(*args)
			out.puts *(args.collect { |a| "#{indent}#{a}"})
		end
	
		def eputs(*args)
			err.puts *(args.collect { |a| "#{indent}#{a}"})
		end
	end
	
	module HierarchalOutputUser
		attr_writer :out
		
		def hierarchal_output
			@hierarchal_output = opts[:out] || HierarchalOutput.new
		end
		
		def puts(*args)
			hierarchal_output.puts *args
		end
		
		def eputs(*args)
			hierarchal_output.eputs *args
		end
		
		def dputs(*args)
			puts(*args) if opts[:debug]
		end
		
		def indented(*args, &block)
			hierarchal_output.indented(*args, &block)
		end
	end
end