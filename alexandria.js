jQuery.extend(Date.prototype, {
	toLocaleFormat: function(str) {
		var daysOfTheWeek = 'Sunday Monday Tuesday Wednesday Thursday Friday Saturday'.split(' ');
		var monthsOfTheYear = 'January February March April May June July August September October November December'.split(' ');
		
		str = str.replace(/%c/g, '%D %T');
		str = str.replace(/%D/g, '%m/%d/%y');
		str = str.replace(/%r/g, '%I:%M:%S %p');
		str = str.replace(/%R/g, '%H:%M');
		str = str.replace(/%T/g, '%H:%M:%S');
		str = str.replace(/%x/g, '%A, %B %d');
		str = str.replace(/%X/g, '%H:%M%p');
		
		str = str.replace(/%a/g, daysOfTheWeek[this.getDay()].substr(0, 3));
		str = str.replace(/%A/g, daysOfTheWeek[this.getDay()])
		
		str = str.replace(/%b/g, monthsOfTheYear[this.getMonth()].substr(0, 3));
		str = str.replace(/%B/g, monthsOfTheYear[this.getMonth()]);
		
		// %c is handled above
		str = str.replace(/%C/g, this.getFullYear() / 100);
		
		str = str.replace(/%d/g, this.getDate());
		// $D is handled above
		
		str = str.replace(/%h/g, monthsOfTheYear[this.getMonth()].substr(0, 3));
		str = str.replace(/%H/g, this.getHours());
		
		str = str.replace(/%I/g, (this.getHours() % 12) + 1);
		
		str = str.replace(/%p/g, this.getHours() < 12 ? "am" : "pm");
		
		str = str.replace(/%S/g, this.getSeconds());
		
		str = str.replace(/%u/g, this.getDay() + 1);
		
		str = str.replace(/%w/g, this.getDay());
		
		str = str.replace(/%m/g, this.getMonth() + 1);
		str = str.replace(/%M/g, this.getMinutes());
		
		str = str.replace(/%y/g, this.getFullYear().toString().substr(2));
		str = str.replace(/%Y/g, this.getFullYear());
		
		return str
	}
});

(function($){
	function userUrl(screenName) {
		if (screenName.substr(0, 1) == '@') screenName = screenName.substr(1);
		return "http://twitter.com/" + screenName;
	}
	
	function tweetUrl(screenName, idStr) {
		return userUrl(screenName) + "/status/" + idStr;
	}

	function tagUrl(tag) {
		return "http://search.twitter.com/?q=#{tag}"
	}
	
	function addEntity(text, entity, wrapper) {
		var range = entity.indices;
		var start = range[0];
		var end = range[1];
		
		var before = text.substr(0, start);
		var during = text.substr(start, end - start);
		var after = text.substr(end);
		
		return before + wrapper(during, entity) + after;
	}
	
	var methods = {
		init: function(opts) {
			var $this = $(this);
			var settings = $.extend({
				tweets: []
			}, opts || {});
			
			$this.data('tweetlib', settings);
			
			$("<div class='controls'>").appendTo($this).append(
				$('<input>').keyup(function() {
					$this.tweetlib('filter', function(tweet) {
						return tweet.text && tweet.text.match($(this).val());
					})
				})
			);
			
			$.each(settings.tweets, function(ix, tweet) {
				var tweetDiv = $this.tweetlib('formatTweetDiv', tweet);
				var dayDiv = $this.tweetlib('getDayDiv', tweet.created_at);
				dayDiv.append(tweetDiv);
			});
			
			$this.find('.tweets-in-month').each(function(ix, monthDiv) {
				monthDiv = $(monthDiv);
				var count = monthDiv.find('.tweet').length;
				var str = count + " tweet" + (count == 1 ? '' : "s");
				monthDiv.children('.meta').text(str);
			});
			$this.find('.tweets-on-day').each(function(ix, dayDiv) {
				dayDiv = $(dayDiv);
				var count = dayDiv.find('.tweet').length;
				var str = count + " tweet" + (count == 1 ? '' : "s");
				dayDiv.find('h4 .meta').text(str);
			});
			return $this;
		},
		formatTweetUrl: function(user_screen_name, id_str) {
			return tweetUrl(user_screen_name, id_str);
		},
		formatTweetDiv: function(tweet) {
			// {"truncated":false,"created_at":"Fri Nov 26 05:04:17 +0000 2010","geo":null,
			//  "favorited":false,"source":"<a href=\"http://twitterrific.com\" rel=\"nofollow\">Twitterrific</a>",
			//  "in_reply_to_status_id_str":"8020197273239552","id_str":"8023212889739265","contributors":null,
			//  "coordinates":null,"in_reply_to_screen_name":"JssSandals","in_reply_to_user_id_str":"15693316",
			//  "place":null,"user":{"id_str":"10588782"}, "retweet_count":null,"retweeted":false,
			//  "text":"@JssSandals but tomorrow's family feast exists in a time warp where it is still Thanksgiving, so no Christmas music there."}
			var $this = this;
			var tweetDiv = $("<div class='tweet'/>").attr('id', tweet.id_str);
			var contentDiv = 	$("<div class='content'>");
			var metaDiv = $("<div class='meta'>");
			
			tweetDiv.data('tweet', tweet);
			tweet.div = tweetDiv;
			tweet.created_at_str = tweet.created_at;
			tweet.created_at = new Date(tweet.created_at_str);
			
			contentDiv.append(tweet.text);
			
			if (tweet.truncated) tweetDiv.append('…');
			if (tweet.favorited) tweetDiv.addClass('favorite');
			if (tweet.retweeted) tweetDiv.addClass('retweeted');
			
			var permalink = $("<a>");
			var user = $this.data('tweetlib').users[tweet.user.id_str] || {};
			permalink.attr('href', tweetUrl(user.screen_name, tweet.id_str));
			permalink.append(tweet.created_at.toString());
			metaDiv.append(permalink);
			
			if (!('autolinked' in tweet)) tweetDiv.addClass('from-archive');
			
			//TODO: add geo
			//TODO: add coordinates
			//TODO: add contributors
			//TODO: add places
			
			metaDiv.append($("<div class='source'>").append('Via ').append(tweet.source));
			
			if (tweet.in_reply_to_screen_name) {
				tweetDiv.addClass('reply');
				var replyDiv = $("<div class='reply-info'>");
				replyDiv.append('In reply to ');
				var replyLink = $('<a>').append(tweet.in_reply_to_screen_name);
				var replyToUrl = (tweet.in_reply_to_status_id_str)
					? tweetUrl(tweet.in_reply_to_screen_name, tweet.in_reply_to_status_id_str)
					: userUrl(tweet.in_reply_to_screen_name);
				replyLink.attr('href', replyToUrl);
				replyDiv.append(replyLink)
				metaDiv.append(replyDiv);
			}
			
			if (tweet.retweet_count) {
				var retweetDiv = $("<div class='retweet-info'>");
				retweetDiv.append("Retweeted " + tweet.retweet_count + " times.");
				metaDiv.append(retweetDiv);
			}
			
			tweetDiv.append(contentDiv)
			tweetDiv.append(metaDiv)
			
			return tweetDiv;
		},
		getDayDiv: function(date) {
			//TODO scope this inside $this
			date = new Date(date);
			var id = date.toLocaleFormat("tweets-on-%Y-%m-%d");
			var div = $('#' + id);
			if (div.length) return div;
			
			return $("<div class='tweets-on-day'>").
				attr('id', id).
				appendTo($(this).tweetlib('getMonthDiv', date)).
				append($('<h4>').
					append(date.toLocaleFormat("%a, %b %d '%y")).
					append($("<div class='meta'>").append('&nbsp;')));
		},
		getMonthDiv: function(date) {
			//TODO scope this inside $this
			date = new Date(date);
			var id = date.toLocaleFormat("tweets-in-%Y-%m");
			var div = $('#' + id);
			if (div.length) return div;
			
			return $("<div class='tweets-in-month'>").
				attr('id', id).
				appendTo($(this)).
				append($('<h4>').append(date.toLocaleFormat("%b '%y"))).
				append($("<div class='meta'>").append('&nbsp;'));
		},
		getTweets: function() {
			return $(this).data('tweetlib').tweets;
		},
		filter: function(predicate) {
			if (typeof(predicate) == "string") {
				var searchTerm = predicate;
				predicate = function(t) {
					return t.text && t.text.toLowerCase().match(searchTerm.toLowerCase());
				}
			}
			
			var $this = $(this);
			$.each($this.tweetlib('getTweets'), function(ix, tweet) {
				if (predicate(tweet)) {
					tweet.div.show();
				} else tweet.div.hide();
			});
			return $this;
		}
	};

	$.fn.tweetlib = function(method) {
		if (methods[method]) {
			return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
		} else if (typeof method === 'object' || ! method) {
			return methods.init.apply(this, arguments);
		} else {
			$.error('Method ' +  method + ' does not exist on jQuery.tweetlib');
		}
	};
	$.extend($.fn.tweetlib, methods);
})(jQuery);

$(document).ready(function() {
	if (!document.location.href.match(/include=all/)) {
		tweets = [
			tweets[0],
			tweets[100],
			tweets[101],
			tweets[200],
			tweets[201],
			tweets[1000],
			tweets[tweets.length - 1]
		];
	}
	tweets = tweets.sort(function(a, b) {
		return a.created_at > b.created_at
			? 1
			: -1;
	});
	$(document.body).tweetlib({tweets: tweets, users: users});
})