chai = require 'chai'
chai.should()
expect = chai.expect

Server = require '../../src/Server'

zmq = require 'zmq'
ports = require '../support/ports'
Q = require 'q'

describe 'Server', ->
  describe '#stop', ->
    it 'should not error if the server has not been started', (done) ->
      server = new Server
        'ce-operation-hub':
          host: 'localhost'
          stream: ports()
          result: ports()
        'ce-delta-hub':
          host: 'localhost'
          stream: ports()
          state: ports()
      server.stop (error) ->
        expect(error).to.not.be.ok
        done()

  describe '#start', ->
    it 'should start and be stoppable', (done) ->
      server = new Server
        'ce-operation-hub':
          host: 'localhost'
          stream: ports()
          result: ports()
        'ce-delta-hub':
          host: 'localhost'
          stream: ports()
          state: ports()
      server.start (error) ->
        expect(error).to.not.be.ok
        server.stop (error) ->
          expect(error).to.not.be.ok
          done()

  describe 'when started', ->
    beforeEach (done) ->
      @ceOperationHub = 
        stream: zmq.socket 'pub'
        result: zmq.socket 'pull'
      ceOperationHubStreamPort = ports()
      @ceOperationHub.stream.bindSync 'tcp://*:' + ceOperationHubStreamPort
      ceOperationHubResultPort = ports()
      @ceOperationHub.result.bindSync 'tcp://*:' + ceOperationHubResultPort
      @ceDeltaHub = 
        stream: zmq.socket 'pull'
        state: zmq.socket 'dealer'
      ceDeltaHubStreamPort = ports()
      @ceDeltaHub.stream.bindSync 'tcp://*:' + ceDeltaHubStreamPort
      ceDeltaHubStatePort = ports()
      @ceDeltaHub.state.bindSync 'tcp://*:' + ceDeltaHubStatePort
      @unknownOperation =
        account: 'Peter'
        sequence: 0
        unknown:
          currency: 'BTC'
          amount: '50'
      @depositOperation1 =
        account: 'Peter'
        sequence: 0     
        deposit:
          currency: 'EUR'
          amount: '5000'
      @depositOperation2 =
        account: 'Peter'
        sequence: 1
        deposit:
          currency: 'BTC'
          amount: '50'
      @submitOperation1 =
        account: 'Peter'
        sequence: 0
        submit:
          bidCurrency: 'EUR'
          offerCurrency: 'BTC'
          bidPrice: '100'
          bidAmount: '50'
      @submitOperation2 =
        account: 'Peter'
        sequence: 1
        submit:
          bidCurrency: 'BTC'
          offerCurrency: 'EUR'
          bidPrice: '20'
          bidAmount: '500'
      @server = new Server
        'ce-operation-hub':
          host: 'localhost'
          stream: ceOperationHubStreamPort
          result: ceOperationHubResultPort
        'ce-delta-hub':
          host: 'localhost'
          stream: ceDeltaHubStreamPort
          state: ceDeltaHubStatePort
      @server.start done

    afterEach (done) ->
      @server.stop =>
        @ceOperationHub.stream.close()
        @ceOperationHub.result.close()
        @ceDeltaHub.stream.close()
        @ceDeltaHub.state.close()
        done()

    it 'should push a result of unknown operation to the ce-operation-hub for published unknown operations', (done) ->
      @ceOperationHub.result.on 'message', (message) =>
        operation = JSON.parse message
        operation.account.should.equal 'Peter'
        operation.sequence.should.equal 0
        operation.result.should.equal 'Error: Unknown operation'
        unknown = operation.unknown
        unknown.currency.should.equal 'BTC'
        unknown.amount.should.equal '50'
        done()
      # wait for sockets to open and connect in case everything is going too quick
      setTimeout =>
        @ceOperationHub.stream.send JSON.stringify @unknownOperation
      , 100

    it 'should push a result of success to the ce-operation-hub and push the balance increase delta to the ce-delta-hub with sequential delta IDs for published deposits', (done) ->
      resultReceived = Q.defer()
      deltaReceived = Q.defer()
      Q.all([
        resultReceived.promise,
        deltaReceived.promise
      ])
      .then((results) =>
        done()
      , done)
      .done()
      secondResult = (message) =>
        operation = JSON.parse message
        operation.account.should.equal 'Peter'
        operation.sequence.should.equal 1
        operation.result.should.equal 'success'
        deposit = operation.deposit
        deposit.currency.should.equal 'BTC'
        deposit.amount.should.equal '50'
        resultReceived.resolve()
      secondDelta = (message) =>
        delta = JSON.parse message
        delta.sequence.should.equal 1
        operation = delta.operation
        operation.sequence.should.equal 1
        operation.account.should.equal 'Peter'
        operation.result.should.equal 'success'
        deposit = operation.deposit
        deposit.currency.should.equal 'BTC'
        deposit.amount.should.equal '50'
        deltaReceived.resolve()        
      firstResult = (message) =>
        operation = JSON.parse message
        operation.account.should.equal 'Peter'
        operation.sequence.should.equal 0
        operation.result.should.equal 'success'
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.should.equal '5000'
        @ceOperationHub.result.removeListener 'message', firstResult
        @ceOperationHub.result.on 'message', secondResult
      firstDelta = (message) =>
        delta = JSON.parse message
        delta.sequence.should.equal 0
        operation = delta.operation
        operation.sequence.should.equal 0
        operation.account.should.equal 'Peter'
        operation.result.should.equal 'success'
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.should.equal '5000'
        @ceDeltaHub.stream.removeListener 'message', firstDelta
        @ceDeltaHub.stream.on 'message', secondDelta
      @ceOperationHub.result.on 'message', firstResult
      @ceDeltaHub.stream.on 'message', firstDelta
      # wait for sockets to open and connect in case everything is going too quick
      setTimeout =>
        @ceOperationHub.stream.send JSON.stringify @depositOperation1
        @ceOperationHub.stream.send JSON.stringify @depositOperation2
      , 100

    it 'should push a result of success to the ce-operation-hub and push the order book delta to the ce-delta-hub with sequential delta IDs for published orders', (done) ->
      resultReceived = Q.defer()
      deltaReceived = Q.defer()
      Q.all([
        resultReceived.promise,
        deltaReceived.promise
      ])
      .then((results) =>
        done()
      , done)
      .done()
      secondResult = (message) =>
        operation = JSON.parse message
        operation.account.should.equal 'Peter'
        operation.sequence.should.equal 1
        operation.result.should.equal 'success'
        submit = operation.submit
        submit.bidCurrency.should.equal 'BTC'
        submit.offerCurrency.should.equal 'EUR'
        submit.bidPrice.should.equal '20'
        submit.bidAmount.should.equal '500'
        resultReceived.resolve()
      secondDelta = (message) =>
        delta = JSON.parse message
        delta.sequence.should.equal 1
        operation = delta.operation
        operation.sequence.should.equal 1
        operation.account.should.equal 'Peter'
        operation.result.should.equal 'success'
        submit = operation.submit
        submit.bidCurrency.should.equal 'BTC'
        submit.offerCurrency.should.equal 'EUR'
        submit.bidPrice.should.equal '20'
        submit.bidAmount.should.equal '500'
        deltaReceived.resolve()        
      firstResult = (message) =>
        operation = JSON.parse message
        operation.account.should.equal 'Peter'
        operation.sequence.should.equal 0
        operation.result.should.equal 'success'
        submit = operation.submit
        submit.bidCurrency.should.equal 'EUR'
        submit.offerCurrency.should.equal 'BTC'
        submit.bidPrice.should.equal '100'
        submit.bidAmount.should.equal '50'
        @ceOperationHub.result.removeListener 'message', firstResult
        @ceOperationHub.result.on 'message', secondResult
      firstDelta = (message) =>
        delta = JSON.parse message
        delta.sequence.should.equal 0
        operation = delta.operation
        operation.sequence.should.equal 0
        operation.account.should.equal 'Peter'
        operation.result.should.equal 'success'
        submit = operation.submit
        submit.bidCurrency.should.equal 'EUR'
        submit.offerCurrency.should.equal 'BTC'
        submit.bidPrice.should.equal '100'
        submit.bidAmount.should.equal '50'
        @ceDeltaHub.stream.removeListener 'message', firstDelta
        @ceDeltaHub.stream.on 'message', secondDelta
      @ceOperationHub.result.on 'message', firstResult
      @ceDeltaHub.stream.on 'message', firstDelta
      # wait for sockets to open and connect in case everything is going too quick
      setTimeout =>
        @ceOperationHub.stream.send JSON.stringify @submitOperation1
        @ceOperationHub.stream.send JSON.stringify @submitOperation2
      , 100

    it 'should error on operations with IDs that have already been executed', (done) ->
      secondResult = (message) =>
        operation = JSON.parse message
        operation.account.should.equal 'Peter'
        operation.sequence.should.equal 0
        operation.result.should.equal 'Error: Operation ID already applied'
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.should.equal '5000'
        done()
      firstResult = (message) =>
        operation = JSON.parse message
        operation.account.should.equal 'Peter'
        operation.sequence.should.equal 0
        operation.result.should.equal 'success'
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.should.equal '5000'
        @ceOperationHub.result.removeListener 'message', firstResult
        @ceOperationHub.result.on 'message', secondResult
        @ceOperationHub.stream.send JSON.stringify @depositOperation1
      @ceOperationHub.result.on 'message', firstResult
      # wait for sockets to open and connect in case everything is going too quick
      setTimeout =>
        @ceOperationHub.stream.send JSON.stringify @depositOperation1
      , 100      

    it 'should error on operations with IDs that are not consecutive', (done) ->
      @ceOperationHub.result.on 'message', (message) =>
        operation = JSON.parse message
        operation.account.should.equal 'Peter'
        operation.sequence.should.equal 1
        operation.result.should.equal 'Error: Operation ID out of sequence'
        deposit = operation.deposit
        deposit.currency.should.equal 'BTC'
        deposit.amount.should.equal '50'
        done()
      # wait for sockets to open and connect in case everything is going too quick
      setTimeout =>
        @ceOperationHub.stream.send JSON.stringify @depositOperation2
      , 100      

    it.skip 'should be up to date with operations from the ce-operation-hub and provide the current state to the ce-delta-hub instance', (done) ->
      done()
