Server = require './Server'
nconf = require 'nconf'

# load configuration
nconf.argv()
config = nconf.get 'config'
if config
  nconf.file
    file: config

server = new Server nconf.get()
console.log JSON.stringify server.options, null, 4

server.start (error) ->
  if error
    console.trace error
  else
    console.log 'ce-engine started'
