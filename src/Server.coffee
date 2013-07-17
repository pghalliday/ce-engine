zmq = require 'zmq'
Engine = require('currency-market').Engine
Operation = require('currency-market').Operation
Amount = require('currency-market').Amount

COMMISSION_REFERENCE = '0.1%'
COMMISSION_RATE = new Amount '0.001'

module.exports = class Server
  constructor: (@options) ->
    @engine = new Engine
      commission:
        account: @options.commission.account
        calculate: (params) ->
          amount: params.amount.multiply COMMISSION_RATE
          reference: COMMISSION_REFERENCE
    @ceOperationHub = 
      stream: zmq.socket 'sub'
      result: zmq.socket 'push'
    @ceOperationHub.stream.subscribe ''
    @ceDeltaHub = 
      stream: zmq.socket 'push'
      state: zmq.socket 'router'
    @ceOperationHub.stream.on 'message', (message) =>
      response =
        operation: message.toString()
      try
        response.operation= new Operation
          json: message
        response.delta = @engine.apply response.operation
      catch error
        response.error = error.toString()
      @ceOperationHub.result.send JSON.stringify response
      if response.delta
        @ceDeltaHub.stream.send JSON.stringify response.delta

  stop: (callback) =>
    @ceOperationHub.stream.close()
    @ceOperationHub.result.close()
    @ceDeltaHub.stream.close()
    @ceDeltaHub.state.close()
    callback()

  start: (callback) =>
    @ceOperationHub.stream.connect 'tcp://' + @options['ce-operation-hub'].host + ':' + @options['ce-operation-hub'].stream
    @ceOperationHub.result.connect 'tcp://' + @options['ce-operation-hub'].host + ':' + @options['ce-operation-hub'].result
    @ceDeltaHub.stream.connect 'tcp://' + @options['ce-delta-hub'].host + ':' + @options['ce-delta-hub'].stream
    @ceDeltaHub.state.connect 'tcp://' + @options['ce-delta-hub'].host + ':' + @options['ce-delta-hub'].state
    callback()
