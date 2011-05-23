
require 'rubygems'

require 'webrick'
#require 'thin'
require 'sinatra'

get '/' do

  content_type 'text/plain'

  [
    `id`,
    `ls -al`
  ].join("\n")
end

