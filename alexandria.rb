#!/usr/bin/env ruby

require 'rubygems'
require 'twitter'
require 'nokogiri'
require 'json'
require 'twitter-text'

Dir["lib/**/*.rb"].each {|rb| require File.join(File.dirname(__FILE__), rb)}

if $0 == __FILE__
	Alexandria::CLI.new(*$*)
end