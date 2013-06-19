zmq = require 'zmq'

module.exports = class Server
  constructor: (@options) ->
    nextOperationId = 0
    nextDeltaId = 0
    @ceOperationHub = 
      stream: zmq.socket 'sub'
      result: zmq.socket 'push'
    @ceOperationHub.stream.subscribe ''
    @ceDeltaHub = 
      stream: zmq.socket 'push'
    @ceOperationHub.stream.on 'message', (message) =>
      operation = JSON.parse message
      if operation.id == nextOperationId
        nextOperationId++
        deposit = operation.deposit
        submit = operation.submit
        if deposit
          operation.result = 'success'
          delta =
            id: nextDeltaId++
            operation: operation
        else if submit
          operation.result = 'success'
          delta =
            id: nextDeltaId++
            operation: operation
        else
          operation.result = 'Error: Unknown operation'
      else
        if operation.id > nextOperationId
          operation.result = 'Error: Operation ID out of sequence'
        else
          operation.result = 'Error: Operation ID already applied'
      @ceOperationHub.result.send JSON.stringify operation
      if delta
        @ceDeltaHub.stream.send JSON.stringify delta



  stop: (callback) =>
    @ceOperationHub.stream.close()
    @ceOperationHub.result.close()
    @ceDeltaHub.stream.close()
    callback()

  start: (callback) =>
    @ceOperationHub.stream.connect 'tcp://' + @options['ce-operation-hub'].host + ':' + @options['ce-operation-hub'].stream
    @ceOperationHub.result.connect 'tcp://' + @options['ce-operation-hub'].host + ':' + @options['ce-operation-hub'].result
    @ceDeltaHub.stream.connect 'tcp://' + @options['ce-delta-hub'].host + ':' + @options['ce-delta-hub'].stream
    callback()
