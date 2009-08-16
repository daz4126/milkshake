require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-validations'

# Database
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/test.db")

require 'models'
require 'controllers'
require 'helpers'

DataMapper.auto_upgrade!
