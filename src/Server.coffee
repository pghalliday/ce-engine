zmq = require 'zmq'

module.exports = class Server
  constructor: (@options) ->
    @ceOperationHub = 
      stream: zmq.socket 'sub'
      result: zmq.socket 'push'
    @ceOperationHub.stream.subscribe ''
    @ceDeltaHub = 
      stream: zmq.socket 'push'
    @ceOperationHub.stream.on 'message', (message) =>
      operation = JSON.parse message
      deposit = operation.deposit
      order = operation.order
      if deposit
        operation.result = 'success'
        delta =
          id: 0
          increase:
            account: operation.account
            currency: deposit.currency
            amount: deposit.amount
      else if order
        operation.result = 'success'
        delta =
          id: 0
          add:
            account: operation.account
            bidCurrency: order.bidCurrency
            offerCurrency: order.offerCurrency
            bidPrice: order.bidPrice
            bidAmount: order.bidAmount
      else
        operation.result = 'unknown operation'
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
