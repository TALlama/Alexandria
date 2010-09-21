require 'ftools'

dir = $1 || 'by_index'
delta = $2 || 0

files = []
Dir.new(dir).each do |f| next unless f =~ /^page_\d+.html$/; files << f end
files.each do |f| 
	n = f.gsub('page_', '').to_i
	new_f = "new_page_#{n + delta}.html"
	puts "#{f} is page #{n}; moving to #{new_f}"
	File.move(f, new_f)
end

new_files = []
Dir.new(dir).each do |f|
	next unless f =~ /^new_page_\d+.html$/
	new_files << f
end
new_files.each do |f|
	new_f = f.gsub('new_', '')
	File.move(f, new_f)
end
