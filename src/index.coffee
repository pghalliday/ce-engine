Server = require './Server'
nconf = require 'nconf'

# load configuration
nconf.argv()
config = nconf.get 'config'
if config
  nconf.file
    file: config
ceOperationHubSubscriber = nconf.get 'ce-operation-hub-subscriber'
ceOperationHubPush = nconf.get 'ce-operation-hub-push'

server = new Server
  ceOperationHubSubscriber: ceOperationHubSubscriber
  ceOperationHubPush: ceOperationHubPush

server.start (error) ->
  if error
    console.log error
  else
    console.log 'ce-engine started'
    console.log '\tce-operation-hub-subscriber: ' + ceOperationHubSubscriber
    console.log '\tce-operation-hub-push: ' + ceOperationHubPush
