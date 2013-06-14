zmq = require 'zmq'

module.exports = class Server
  constructor: (@options) ->
    @ceOperationHub = 
      stream: zmq.socket 'sub'
      result: zmq.socket 'push'
    @ceOperationHub.stream.subscribe ''
    @ceOperationHub.stream.on 'message', (message) =>
      order = JSON.parse message
      order.status = 'success'
      @ceOperationHub.result.send JSON.stringify order

  stop: (callback) =>
    @ceOperationHub.stream.close()
    @ceOperationHub.result.close()
    callback()

  start: (callback) =>
    @ceOperationHub.stream.connect 'tcp://' + @options['ce-operation-hub'].host + ':' + @options['ce-operation-hub'].stream
    @ceOperationHub.result.connect 'tcp://' + @options['ce-operation-hub'].host + ':' + @options['ce-operation-hub'].result
    callback()
