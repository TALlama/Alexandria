# History

[Twitter](http://twitter.com) is great; I use it [all the time](http://twitter.com/TALlama). But it has two huge issues:

1. It's [search feature](http://search.twitter.com) never finds anything older than a few days
2. The API won't let you access anything more than your 3000 most recent tweets

I often want to find a tweet that fits neither of those criteria to follow a link or grab an image or whatnot. So sometime before I hit the 3000 mark I wrote a [tool](https://github.com/TALlama/Alexandria/blob/master/twitter_scraper.rb) that would scrape the Twitter website and save the tweets into a HTML file. It was a dirty hack; I knew Twitter had an API, but I didn't use it because I was lazy.

Then "New Twitter" came around and my dirty hack broke. At that moment a counter started; when I hit 3000 tweets after that I'd lose things. And I couldn't lose things; I'm obsessive like that.

So I grabbed the [Twitter Gem](http://twitter.rubyforge.org/) and made a real solution. This one can read directly from the API, or from a JSON file stored locally, or from its own "tweetlib" format, or from the legacy "tweet-archive" format from the broken scraper. It can output to JSON or tweetlib files. It can mix and match inputs and outputs. It makes julienne fries.*

It's also just a fun way to spend some time writing Ruby and playing around with [TDD](http://en.wikipedia.org/wiki/Test-driven_development) and [RSpec](http://rspec.info/).

* Product does not actually make julienne fries.

# Use

Using Alexandria is simple:

    alexandria.rb update TALlama

That will pull down as much history as it can for the user `TALlama` and update their local tweetlib. If a tweetlib exists it will notice and pull tweets from there first; it will stop hitting the API once it finds a duplicate from the file, so subsequent updates are simple and fast.

You can also tell it to pull from specific places, or in specific orders:

    # pull from an old-school Twitter HTML page, then hit the API
    alexandria.rb update TALlama --source archive --source api

And you can tell it what format to output:

    # don't save to HTML; just save to JSON
    alexandria.rb update TALlama --dest json

Or you can just tell it what filename to use:

    alexandria.rb update TALlama --opt lib_file Tweets.html

And you can even pull from one file and output to another, if you want to re-parse for some reason:

    alexandria.rb update TALlama --opt in_lib_file OldTweets.html --opt out_lib_file NewTweets.html

# License

This code is released under the MIT License; use it as you wish.

# Issues

Find something wrong? [Tell me](https://github.com/TALlama/Alexandria/issues)!