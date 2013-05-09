# use from irb for now. will learn thor next

require 'twitter'
require 'mongo_mapper'
require_relative '../secrets/twitter_keys'

MongoMapper.database = 'twitters'

Twitter.configure do |config|
  config.consumer_key = TwitterKeys::CONSUMER_KEY
  config.consumer_secret = TwitterKeys::CONSUMER_SECRET
  config.oauth_token = TwitterKeys::OAUTH_TOKEN
  config.oauth_token_secret = TwitterKeys::OAUTH_TOKEN_SECRET
end

class Tweet
  include MongoMapper::Document
  key :id, Fixnum
  key :text, String
  key :user_id, Integer
  key :user_name, String
  key :user_screen_name, String
  key :user_location, String
end

def store_tweet(tweet, query_phrase)
  t = Tweet.new
  t.id = tweet.id
  t.text = tweet.full_text
  t.user_id = tweet[:user][:id]
  t.user_name = tweet[:user][:name]
  t.user_screen_name = tweet[:user][:screen_name]
  t.user_location = tweet[:user][:location]
  t.query_phrase = query_phrase
  t.save
end

def quick_search
  print "     Search:   "
  STDOUT.flush
  term = gets.chomp

  Twitter.search(term, :count => 100).results.each do |tweet| 
    print "\n     #{tweet.text}\n"
    store_tweet(tweet, term)
  end
  print "----------#{Tweet.count}----------\n\n"
end

def location_strings
  freq = Hash.new(0)
  locations = Tweet.all.collect {|tweet| tweet.user_location}
  
  for l in locations
    location = l == "" ? "unspecified" : l
    freq[location] += 1
  end

  return freq.sort_by {|word, count| count}.reverse
end

def print_hash(things)
  things.each {|a, b| print " #{a}:  #{b}\n"}
end

Tweet.ensure_index [[:id, 1]], :unique => true