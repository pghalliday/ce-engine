zmq = require 'zmq'

module.exports = class Server
  constructor: (@options) ->
    @ceOperationHubSubscriber = zmq.socket 'sub'
    @ceOperationHubSubscriber.subscribe ''
    @ceOperationHubPush = zmq.socket 'push'
    @ceOperationHubSubscriber.on 'message', (message) =>
      order = JSON.parse message
      order.status = 'success'
      @ceOperationHubPush.send JSON.stringify order

  stop: (callback) =>
    @ceOperationHubSubscriber.close()
    @ceOperationHubPush.close()
    callback()

  start: (callback) =>
    @ceOperationHubSubscriber.connect @options.ceOperationHubSubscriber
    @ceOperationHubPush.connect @options.ceOperationHubPush
    callback()
