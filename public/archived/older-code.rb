######################################################
## older routes, less optimal for various reasons
## maybe helpful to reference
######################################################

# making sure sending tweets work
get '/test-tweet' do
  begin
     Twitter.update("Hi there! I'm the NitPickster!")
  rescue
     "Tweet not sent :("
  else
     'Tweet sent!'
  end
end

# fetch new tweets and put them in db
get '/fetch-tweets' do
  repeats = 0
  additions = 0
  url = "http://search.twitter.com/search.json?q=%22reed%20a%20book%22%20-RT"
  data = HTTParty.get(url)
  tweets = data['results']
  
  tweets.each do |tweet|
    id = tweet['id']
    if Tweet.all(:tweet_id => id).length == 0
      additions += 1  
      t = Tweet.new
      t.tweet_id = id
      t.user_name = tweet['from_user']
      t.user_name = tweet['from_user']
      t.user_id = tweet['from_user_id']
      t.message = tweet['text']
      t.category = "reed_a_book"
      t.created_at = Time.now  
      t.updated_at = Time.now  
      t.save
    else
      repeats += 1
    end
  end
  "Complete: #{additions} new entries; #{repeats} repeat entries"
end

# for checking stuff
get '/blah' do
  @nitpicks = Tweet.all
  "#{@nitpicks.class}"
end

# for playing around with styling
get '/playground' do
  erb :playground
end

# making sure db inserts work
get '/db-add' do
  t = Tweet.new
  t.tweet_id = "285707119985061889"
  t.message = 'dfsdfsd'
  t.created_at = Time.now  
  t.updated_at = Time.now  
  t.save
  "done."
end

# fetch new tweets and put them in db
get '/fetch-tweets' do
  repeats = 0
  additions = 0
  nitpicks.each do |nit|
    # define new url
    wrong_phrase = nit[0]
    proper_phrase = nit[1]
    url = make_twitter_url(wrong_phrase)
    # fetch json data 
    data = HTTParty.get(url)
    tweets = data['results']
    # loop through tweets
    tweets.each do |tweet|
      id = tweet['id']
      # add them to db if not already there
      if Tweet.all(:tweet_id => id).length == 0
        additions += 1  
        t = Tweet.new
        t.tweet_id = id.to_s
        t.user_name = tweet['from_user']
        t.user_id = tweet['from_user_id'].to_s
        t.message = tweet['text']
        t.wrong_usage = wrong_phrase
        t.proper_usage = proper_phrase
        t.created_at = Time.now  
        t.updated_at = Time.now  
        t.save
      else
        repeats += 1
      end
    end   
  end
  "Complete: #{additions} new entries; #{repeats} repeat entries"
end

# to delete a specific row from table
get '/kill/specific/:id' do
  id = params[:id].to_i
  tweet = Tweet.get(id)
  if tweet.nil?
    "not on the list :("
  else
    tweet.destroy
    "tweet deleted"
  end
end

# to delete all rows greater than id specified
get '/kill/greater/:id' do
  counter = 0
  id = params[:id].to_i
  id = "blah" if id == 0
  tweets = Tweet.all(:id.gte => id)
  if tweets == []
    "nope."
  else
    tweets.each { |t| counter += 1 }
    tweets.destroy
    "#{counter} deleted."
  end
end

# email testing
get '/email' do
  Pony.mail(:to => 'brendan@etsy.com', :from => 'brendansudol@gmail.com', :subject => 'Hello')
  'email sent!'
end

######################################################
## html / js
######################################################

# <!-- <hr>
# 
# <section id="tweets">
# <div class='row-fluid'>
#   <div class='tweet-stream'>
#     <a class="twitter-timeline" href="https://twitter.com/TheNitPickster" data-widget-id="286668035706716160">Loading tweets; one moment please...</a>
#   </div>
# </div>
# </section> -->

# new account
# !function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0];if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src="//platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");

# <hr>
# <div class="examples">
#   <p class="lead">For Example: </p>
#   <div class='row-fluid'>
#     <div class='ex1'>
#       <img class="img-rounded" src="/css/images/nitpick_ex<%= @pic_number %>.png" alt="Example Response">
#     </div>
#   </div>
# </div>
