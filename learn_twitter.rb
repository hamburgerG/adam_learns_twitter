require 'twitter'
require 'mongo_mapper'
require 'highline/import'
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

module Actions
  def store_tweets(tweets, query_phrase)
    tweets.each do |tweet|
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
  end

  def quick_search(term)
    new_tweets = Twitter.search(term, :count => 100).results
    store_tweets(new_tweets, term)
    return new_tweets
  end

  def location_string_freqs
    freq = Hash.new(0)
    locations = Tweet.all.collect { |tweet| tweet.user_location}
    
    locations.each do |location|
      if location == ""
        freq["unspecified"] += 1
      else
        freq[location] += 1
      end
    end

    return freq.sort_by { |word, count| count}.reverse
  end

  def print_hash(things)
    colors = %w{black red green yellow blue magenta cyan white}
    things.each_with_index do |(l, c), i|
      clr = colors[7 - i % 7]
      say("<%= color('#{l} : #{'X'*c}', :#{clr}, :bold, :blink) %>")
    end
  end
end

Tweet.ensure_index [[:id, 1]], :unique => true