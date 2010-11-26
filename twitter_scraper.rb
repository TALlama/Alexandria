#!/usr/bin/ruby

require 'tmpdir'
require 'date'
require 'fileutils'
require 'ftools'
require 'net/http'

loaded_find_so_far = true
['rubygems', 'hpricot', 'active_support'].each do |lib|
	begin
		require lib
	rescue LoadError => err
		STDERR.puts "Could not find a required dependency; try the following to install:" if loaded_find_so_far
		STDERR.puts "$ sudo gem install #{lib}"
		
		loaded_find_so_far = false
	end
end

exit(1) if !loaded_find_so_far

DELETE_ARCHIVE_BEFORE = false
DELETE_INDEX_CACHE_AFTER = true
VERBOSE = true

class Fixnum
	def to_s_nice
		self.to_s.gsub(/(\d)(?=\d{3}+(\.\d*)?$)/, '\1,')
	end
end

module Athena
	class Exception < ::StandardError
	end
	
	class Tweet
		attr_accessor :user_name
		attr_accessor :id
		attr_accessor :content
		attr_accessor :timestamp
		attr_accessor :client_name, :client_url
		attr_accessor :in_reply_to_name, :in_reply_to_url
		
		def self.parse_all_from_page(page)
			tweets = []
			doc = Hpricot(page)
			
			title = doc.at('//title').html
			throw Exception.new(title) if title =~ /Twitter \//
			
			# fix up relative URLs
			doc.search('//a[@href]') do |anchor|
				anchor["href"] = anchor["href"].sub(/^\//, "http://twitter.com/")
			end
			
			# now parse out the tweets
			doc.search('//.status') do |tweet|
				tweets << Tweet.parse_status_div(tweet)
			end
			
			tweets
		end
		
		def self.parse_status_div(d)
			############# A normal tweet
			#<li class="hentry u-TALlama status" id="status_4993369766">
			#	 <span class="status-body">
			#		 <span class="entry-content">The Superfreakonomics guys are really, 
			#			 really wrong about global warming, and here's why: 
			#			 <a href="http://bit.ly/1M05fo" class="tweet-url web" rel="nofollow" target="_blank">http://bit.ly/1M05fo</a>
			#		 </span>
			#		 <span class="meta entry-meta">
			#			 <a href="http://twitter.com/TALlama/status/4993369766" class="entry-date" rel="bookmark">
			#				 <span data="{time:'Mon Oct 19 15:30:29 +0000 2009'}" 
			#					 class="published timestamp">8:30 AM Oct 19th</span>
			#			 </a>
			#			 <span>from <a href="http://bit.ly" rel="nofollow">bit.ly</a></span>
			#		 </span>
			#	 </span>
			#</li>
			
			############## A reply
			#<li class="hentry u-TALlama status" id="status_5034174917">
			#	 <span class="status-body">
			#		 <span class="entry-content">@<a class="tweet-url username" href="/lemmo">lemmo</a> 
			#			 that was awesome.
			#		 </span>
			#		 <span class="meta entry-meta">
			#			 <a href="http://twitter.com/TALlama/status/5034174917" class="entry-date" rel="bookmark">
			#				 <span class="published timestamp" data="{time:'Wed Oct 21 02:18:54 +0000 2009'}"
			#					 >7:18 PM Oct 20th</span>
			#			 </a>
			#			 <span>from <a href="http://twitterrific.com" rel="nofollow">Twitterrific</a></span>
			#			 <a href="http://twitter.com/lemmo/status/5034093400">in reply to lemmo</a>
			#		 </span>
			#	 </span>
			#</li>
			
			t = Tweet.new
			
			t.user_name = d['class'].split.collect {|c| c[/^u-(.+)$/, 1]}.compact.first
			t.id = d['id'].split('_').last.to_i
			t.content = d.at('.entry-content').html
			
			timestamp_span = d.at('.timestamp')
			t.timestamp = DateTime.parse(ActiveSupport::JSON.decode(timestamp_span['data'])['time'])
			
			meta = d.at('.entry-meta')
			
			client_link = meta.at('/span/a')
			if client_link #web updates have no client link
				t.client_name = client_link.html
				t.client_url = client_link['href']
			else
				t.client_name = 'web'
				t.client_url = 'http://twitter.com'
			end
			
			# it'd be nice if the markup had a class for this
			in_reply_to_link = meta.search('a').select do |a|
				a.html =~ /in reply to/
			end.first
			if in_reply_to_link
				t.in_reply_to_name = in_reply_to_link.html.split.last
				t.in_reply_to_url = in_reply_to_link['href']
			end
			
			t
		ensure
			STDERR.puts "Problem parsing tweet: #{$!}", "-" * 80, d.html, "-" * 80 if $!
		end
		
		def self.archive(to_file, tweets, options={})
			options = {
				:group_by => Proc.new do |tweet|
					format = options[:group_by_time_format] || '%B ‘%y'
					tweet.timestamp.strftime(format)
				end
			}.merge(options)
			
			tweets = tweets.flatten
			
			if options[:filter]
				filter = options[:filter]
				
				filter = Proc.new {|t| t.content =~ options[:filter]} if filter.is_a? Regexp
				
				tweets = tweets.select &filter if filter.is_a? Proc
			end
			
			tmp_file = to_file.gsub(/\./, '.tmp.')
			File.open(tmp_file, "w+") do |f|
				f.puts %{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">}
				f.puts %{<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">}
				f.puts %{ <head><title>#{options[:title] || "Twitter Archive"}</title>}
				f.puts %{		<meta content="text/html; charset=utf-8" http-equiv="Content-Type" />}
				f.puts %[
					<style type='text/css'>
						#timeline {
							margin: 0 0 0 5em;
							width: 50em;
						}
						
						#timeline li {
							color: #eee;
							margin-bottom: .3em;
						}
						
						#timeline li li:hover {
							color: #999;
							background-color: #f6f6ff;
						}
						
						#timeline li ol {
							border-left: 1px solid #eee;
							border-bottom: 1px solid #eee;
							margin-top: .5em;
							margin-bottom: .5em;
						}
						
						li span {
							color: black;
						}
						
						#stats {
							float: right;
							border: 1px dashed black;
							padding: 1em;
							margin: .5em;
							background-color: white;
						}
						
						.aggregate-stats,
						.so-far {
							font-weight: normal;
							font-size: 80%;
							color: #999;
						}
						
						.aggregate-stats p {
							margin: 0;
							padding: 0;
						}
						
						.entry-meta {
							margin-left: 1em
						}
						
						li .entry-meta span,
						li .entry-meta a, 
						li .entry-meta a:hover, 
						li .entry-meta a:visited {
							color: #999; 
							font-size: 80%; 
						}
					</style>]
				f.puts "	</head>"
				f.puts "	<body>"
				f.puts TweetStats.new(tweets, options).to_html unless options[:no_stats]
				f.puts "		<div id='timeline'>"
				f.puts "			<ol>"
				
				sections = tweets.group_by &options[:group_by]
				sections.each_pair do |section, tweets_in_section|
					f.puts "				<li>"
					if section
						f.puts "<span class='section-name'>#{section}</span>"
						f.puts " <span class='aggregate-stats'>#{tweets_in_section.length} tweets</span>"
					end
					f.puts "					<ol>"
					f.puts tweets_in_section
					f.puts "					</ol>"
					f.puts "				</li>"
				end
				
				f.puts "			</ol>"
				f.puts "		</div>"
				f.puts "	</body>\n</html>"
			end
			
			File.delete(to_file) if File.exist?(to_file)
			File.move(tmp_file, to_file)
			
			to_file
		end
		
		def url
			"http://twitter.com/#{user_name}/status/#{id}"
		end
		
		def local_timestamp
			self.timestamp.new_offset(DateTime.now.offset)
		end
		
		def reply?
			!self.in_reply_to_url.nil?
		end
		
		def to_s
			reply_html = reply? ? %{
				<a href='#{in_reply_to_url}' class='in-reply-to'>in reply to #{in_reply_to_name}</a>
			} : ''
			
			%{
				<li class='status' id='status_#{id}'>
					<span class='entry-content'>#{content}</span>
					<span class='entry-meta'>
						<a href='#{url}' class='entry-date' rel='bookmark'><span 
							data="{time: '#{timestamp}'}" class='timestamp published'>#{local_timestamp.strftime('%X on %x')}</span></a>
						<span class='entry-client'>from <a href='#{client_url}'>#{client_name}</a></span>
						#{reply_html}
					</span>
				</li>
			}
		end
		
		def <=>(rhs)
			self.id <=> rhs.id
		end
	end
	
	class TweetStats
		def initialize(tweets, options)
			@user = tweets.first.user_name rescue ''
			
			@count_by_date = Hash.new(0)
			
			@client_counts_by_name = Hash.new(0)
			@client_urls_by_name = {}
			
			@reply_counts_by_name = Hash.new(0)
			
			tweets.each do |tweet|
				date = Date.parse(tweet.timestamp.to_s)
				@count_by_date[date] = @count_by_date[date] + 1
				
				client = tweet.client_name
				@client_counts_by_name[client] = @client_counts_by_name[client] + 1
				@client_urls_by_name[client] = tweet.client_url
				
				if tweet.reply?
					@reply_counts_by_name[tweet.in_reply_to_name] = @reply_counts_by_name[tweet.in_reply_to_name] + 1
				end
			end
		end
		
		def to_html_top_list(name, count_by_item, options={})
			html = []
			
			count_by_section = Hash.new(0)
			if options[:item_to_section]
				count_by_item.each_pair do |item, count|
					section = options[:item_to_section].call(item)
				
					count_by_section[section] = count_by_section[section] + count
				end
			else
				count_by_section = count_by_item
			end
			
			sorted_sections = count_by_section.keys.sort
			last_x_count = options[:last_x] || 10
			last_x_sections = sorted_sections.slice(sorted_sections.length - last_x_count, last_x_count) || []
			
			total = 0
			ordered_counts = []
			count_by_section.each_pair do |section, count|
				ordered_counts << [count, section]
				total = total + count
			end
			ordered_counts.sort!
			ordered_counts.reverse!
			average = total / ordered_counts.length
			
			last_x_sections_total = 0
			last_x_sections.each do |section|
				count = count_by_section[section]
				last_x_sections_total += count
			end
			last_x_sections_average = last_x_sections_total / last_x_count
			
			stats = {
				:total => total,
				:average => average,
				:ordered_counts => ordered_counts,
				:sorted_sections => sorted_sections,
				:last_x_sections => last_x_sections,
				:count_by_item => count_by_item,
				:count_by_section => count_by_section,
				:options => options
			}
			
			aggregate_additional = options[:aggregate_additional] || ''
			if aggregate_additional.respond_to? :call
				aggregate_additional = aggregate_additional.call(stats)
			end
			aggregate_stats_html = %{<div class='aggregate-stats'>
				<p>#{average.to_s_nice} average overall</p>
				<p>#{last_x_sections_average.to_s_nice} average last #{last_x_count}</p>
				#{aggregate_additional}
			</div>}
			
			ordered_counts = ordered_counts.slice(0, options[:max]) if options[:max]
			
			html << " <div><h3>#{name} #{aggregate_stats_html unless options[:aggregate_stats] == false}</h3>"
			html << '		<ol>'
			ordered_counts.each do |record| 
				section = raw_section = record.last
				section = options[:section_formatter].call(section) if options[:section_formatter]
				count = record.first
				if options[:url]
					url = options[:url].call(section)
					section = "<a href='#{url}'>#{section}</a>"
				end
				section_html = "#{section}: #{count.to_s_nice}"
				if options[:section_html_formatter] and options[:section_html_formatter].respond_to? :call
					section_html = options[:section_html_formatter].call(section_html, raw_section, section, count, stats)
				end
				html << "			<li>#{section_html}</li>"
			end
			html << '		</ol>' << ' </div>'
			
			return html
		end
		
		def to_html
			html = []
			
			html << "<div id='stats'><h2>Stats</h2>"
			html << "<p><a href='http://tweetstats.com/status/#{@user}'>More</a></p>"
			
			html << to_html_top_list("Top Months", @count_by_date, 
				:max => 10,
				:item_to_section => Proc.new do |date| 
					Date.new(date.year, date.month, 1)
				end,
				:section_formatter => Proc.new {|date| date.strftime('%B ‘%y') },
				:section_html_formatter => Proc.new do |defaultHtml, raw_section, section, count, data|
					today = Date.today
					this_month = Date.new(today.year, today.month, 1)
					
					if this_month == raw_section
						end_of_this_month = Date.new(today.year, today.month, -1)
						percentage = today.mday.to_f / end_of_this_month.mday.to_f * 100
						multiplier = (end_of_this_month.mday.to_f / today.mday.to_f)

						so_far_this_month = data[:count_by_section][this_month]
						expected_month_end = (multiplier * so_far_this_month).to_i

						defaultHtml + %{ <div class='so-far'>
							so far; expected total is #{expected_month_end}
						</div>}
					else
						defaultHtml
					end
				end,
				:last_x => 5
			)
			html << to_html_top_list("Top Days", @count_by_date, 
				:max => 10,
				:section_formatter => Proc.new {|date| date.strftime('%x') },
				:last_x => 20
			)
			
			html << to_html_top_list("Top Clients", @client_counts_by_name, 
				:aggregate_stats => false,
				:url => Proc.new {|client| @client_urls_by_name[client]}
			)
			
			html << to_html_top_list("Replies", @reply_counts_by_name, 
				:aggregate_stats => false,
				:url => Proc.new { |reply_to| "http://twitter.com/#{reply_to}" },
				:section_formatter => Proc.new do |reply_to| 
					reply_to
				end
			)
			
			html << '</div>'
			
			html.flatten.join("\n\t\t")
		end
	end
	
	class TimelinePage
		attr_accessor :user
		attr_accessor :index
		
		def self.index_cache_dir(user)
			File.join(user.cache_dir, 'by_index')
		end
		
		def self.clear_index_cache_dir(user)
			dir = self.index_cache_dir(user)
			Dir.foreach(dir) do |f| 
				File.delete(File.join(dir, f)) unless f == '.' or f == '..'
			end
			Dir.delete(dir)
		end
		
		def initialize(user, index)
			self.user = user
			self.index = index
		end
		
		def from_cache=(v)
			@from_cache = v
		end
		
		def from_cache?
			@from_cache
		end
		
		def index_cache_file
			dir = TimelinePage.index_cache_dir(user)
			Dir.mkdir(dir) unless File.exists?(dir)
			
			File.join(dir, "page_#{index}.html")
		end
		
		def delete_index_cache_file
			File.delete(index_cache_file) if File.exists?(index_cache_file)
		end
		
		def url
			@url ||= URI.parse("http://twitter.com/#{user.name}?page=#{index}")
		end
		
		def get(options={})
			out = options[:out] || STDOUT
			
			return @page_contents if @page_contents
			
			if File.exists? index_cache_file
				out.puts "		(pulling from cache at #{index_cache_file})"
				self.from_cache = true
				return @page_contents = File.read(index_cache_file)
			elsif VERBOSE
				out.puts "		downloading #{url}"
				out.puts "		saving to #{index_cache_file}"
			end
			
			@page_contents = ""
			
			res = Net::HTTP.start(url.host, url.port) {|http|
				http.get(url.path + "?page=#{index}")
			}
			
			if res.is_a? Net::HTTPSuccess
				@page_contents = res.body
				File.open(index_cache_file, "w+") { |io| io << @page_contents }
			else
				raise Exception, "Error getting page #{index}: #{res.message} [#{res.code}]"
			end

			@page_contents
		end
		
		def tweets
			return @tweets if @tweets
			
			@tweets = Tweet.parse_all_from_page(self.get).reverse
		end
	end

	class User
		attr_accessor :name
		
		def initialize(name)
			self.name = name
			
			@tweets = {}
		end
		
		def cache_dir
			@cache_dir = File.join(Dir.tmpdir, "twitter_scraper", self.name)
			[File.dirname(@cache_dir), @cache_dir].each do |d|
				Dir.mkdir(d) unless File.exists? d
			end
			@cache_dir
		end
		
		def get_tweets_from_web(options = {})
			page_range = options[:page_range]
			out = options[:out] || STDOUT
			err = options[:err] || STDERR
			
			page_index = page_range ? page_range.first : 1
			page_index = 1 if page_index < 1
			
			page_range_desc = page_range ? "pages #{page_range.inspect}" : "all pages"
			out.puts "Getting #{page_range_desc} of #{name}'s tweets…"
			
			loop do
				out.puts "	Getting page #{page_index}"
				page = TimelinePage.new(self, page_index)
				
				begin
					page.get(options)
					add_tweets(page.tweets) or return
					out.puts "		got #{page.tweets.size} tweets"
					page_index = page_index.succ
					
					break if page.tweets.empty?
					break if page_range and page_index >= page_range.last
					
					sleep 1 unless page.from_cache?
				rescue Exception => e
					err.puts "", "Got an error getting page #{page_index}: #{e.message}"
					page.delete_index_cache_file
					exit(1)
				end
			end
		end
		
		def archive_file
			"#{name}-tweet-archive.html"
		end
		
		def delete_archive_file
			File.delete(archive_file) if File.exists?(archive_file)
		end
		
		def get_tweets_from_archive(options={})
			out = options[:out] || STDOUT
			
			out.puts "Pulling from archive"
			if File.exists?(archive_file)
				tweets = Tweet.parse_all_from_page(File.read(archive_file))
				out.puts "	Got #{tweets.length} tweets from archive"
				
				add_tweets(tweets)
			else
				out.puts "	No archive to pull from"
			end
		end
		
		def archive_tweets(options={})
			to_file = options[:to_file] || archive_file
			
			delete_archive_file if DELETE_ARCHIVE_BEFORE
			get_tweets(options)
			
			TimelinePage.clear_index_cache_dir(self) if DELETE_INDEX_CACHE_AFTER
			Tweet.archive(to_file, self.tweets, options)
		end
		
		def get_tweets(options={})
			get_tweets_from_archive(options)
			get_tweets_from_web(options)
		end
		
		def add_tweets(tweets)
			retval = true
			
			tweets.each do |tweet|
				if @tweets[tweet.id]
					retval = false
				end
				
				@tweets[tweet.id] = tweet
			end
			
			retval
		end
		
		def tweets
			get_tweets if @tweets.empty?
			
			@tweets.keys.sort.collect { |id| @tweets[id] }
		end
	end
end

if $0 == __FILE__
	username=$1 || 'TALlama'
	user = Athena::User.new(username)
	file = user.archive_tweets(
		#:group_by => Proc.new {|tweet| tweet.timestamp.strftime('%x')},
		#:group_by => Proc.new {|tweet| tweet.content.length},
		#:group_by_time_format => '%x',
		#:filter => Proc.new {|tweet| tweet.content =~ /MikaylaRoby/}
		#:filter => /MikaylaRoby/
	)
	puts "Got #{user.tweets.length} tweets"

	%x{open #{file}}
end
