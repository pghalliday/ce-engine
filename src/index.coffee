Server = require './Server'
nconf = require 'nconf'

# load configuration
nconf.argv()
config = nconf.get 'config'
if config
  nconf.file
    file: config

server = new Server
  ceOperationHubSubscriber: nconf.get 'ce-operation-hub-subscriber'
  ceOperationHubPush: nconf.get 'ce-operation-hub-push'

server.start (error) ->
  if error
    console.log error
  else
    console.log 'ce-engine started'
    console.log '\tce-operation-hub-subscriber: ' + nconf.get 'ce-operation-hub-subscriber'
    console.log '\tce-operation-hub-push: ' + nconf.get 'ce-operation-hub-push'
