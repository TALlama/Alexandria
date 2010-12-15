#!/usr/bin/env ruby

if RUBY_VERSION < "1.9"
	$KCODE = "u"
end

require 'rubygems'
require 'twitter'
require 'nokogiri'
require 'json'
require 'twitter-text'

Dir["lib/**/*.rb"].each {|rb| require File.join(File.dirname(__FILE__), rb)}

if $0 == __FILE__
	Alexandria::CLI.new(*$*)
end