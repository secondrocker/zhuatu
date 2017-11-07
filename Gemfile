source "https://ruby.taobao.org"
#ruby=ruby-2.4.1
gem 'rack'
gem 'sinatra'
gem 'haml'
gem 'json'

gem 'oj'
gem 'rest-client'
gem 'nokogiri'

gem 'activerecord','< 5.0.0', :require => 'active_record'
gem 'will_paginate'
gem 'dalli', :require => 'active_support/cache/dalli_store'
gem 'kgio'
gem "second_level_cache"
gem 'mysql2'

gem 'rake'
# gem 'pony'   # pony must be after activerecord

group :production do
  gem 'rainbows'
end

group :development do
  gem 'thin'
  gem 'pry'
  gem 'sinatra-contrib'
end

group :test do
  gem 'minitest', :require => "minitest/autorun"
  gem 'rack-test', :require => "rack/test"
  gem 'factory_girl'
  gem 'database_cleaner'
end
