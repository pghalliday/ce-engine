Server = require './Server'
nconf = require 'nconf'

# load configuration
nconf.argv()
config = nconf.get 'config'
if config
  nconf.file
    file: config

server = new Server nconf.get()
console.log server.options

server.start (error) ->
  if error
    console.log error
  else
    console.log 'ce-engine started'
