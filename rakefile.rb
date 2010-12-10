require 'rake'
require 'rubygems'
require 'rspec/core/rake_task'

namespace :test do
	task :all => [:rspec]
	
	RSpec::Core::RakeTask.new do |t|
		t.pattern = "spec/**/#{ENV["SPECS"] || "*"}_spec.rb"
		t.rspec_opts = %w{}
		t.rspec_opts << '--colour' if $stdout.isatty
		if RUBY_VERSION[0..2] == '1.8'
			t.rcov = true
			t.rcov_opts = %w{--exclude /Library 
				--exclude spec 
				--comments 
				--css spec/custom.css}
		end
	end
end