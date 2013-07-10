chai = require 'chai'
chai.should()
expect = chai.expect

Server = require '../../src/Server'

zmq = require 'zmq'
ports = require '../support/ports'
Q = require 'q'

Operation = require('currency-market').Operation
Delta = require('currency-market').Delta
Amount = require('currency-market').Amount

describe 'Server', ->
  describe '#stop', ->
    it 'should not error if the server has not been started', (done) ->
      server = new Server
        commission:
          account: 'commission'
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
        commission:
          account: 'commission'
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
      @depositOperation1 = new Operation
        reference: '550e8400-e29b-41d4-a716-446655440000'
        account: 'Peter'
        deposit:
          currency: 'EUR'
          amount: new Amount '5000'
      @depositOperation1.accept
        sequence: 0
        timestamp: Date.now()
      @depositOperation2 = new Operation
        reference: '550e8400-e29b-41d4-a716-446655440000'
        account: 'Peter'
        deposit:
          currency: 'BTC'
          amount: new Amount '50'
      @depositOperation2.accept
        sequence: 1
        timestamp: Date.now()
      @submitOperation1 = new Operation
        reference: '550e8400-e29b-41d4-a716-446655440000'
        account: 'Peter'
        submit:
          bidCurrency: 'EUR'
          offerCurrency: 'BTC'
          offerPrice: new Amount '100'
          offerAmount: new Amount '50'
      @submitOperation1.accept
        sequence: 2
        timestamp: Date.now()
      @submitOperation2 = new Operation
        reference: '550e8400-e29b-41d4-a716-446655440000'
        account: 'Peter'
        submit:
          bidCurrency: 'BTC'
          offerCurrency: 'EUR'
          bidPrice: new Amount '100'
          bidAmount: new Amount '50'
      @submitOperation2.accept
        sequence: 3
        timestamp: Date.now()
      @server = new Server
        commission:
          account: 'commission'
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

    it 'should push deltas to the ce-operation-hub and the ce-delta-hub with sequential delta IDs for published operations', (done) ->
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
      fourthResult = (message) =>
        response = JSON.parse message
        operation = new Operation
          exported: response.operation
        operation.sequence.should.equal 3
        operation.account.should.equal 'Peter'
        submit = operation.submit
        submit.bidCurrency.should.equal 'BTC'
        submit.offerCurrency.should.equal 'EUR'
        submit.bidPrice.compareTo(new Amount '100').should.equal 0
        submit.bidAmount.compareTo(new Amount '50').should.equal 0
        delta = new Delta 
          exported: response.delta
        delta.sequence.should.equal 3
        operation = delta.operation
        operation.sequence.should.equal 3
        operation.account.should.equal 'Peter'
        submit = operation.submit
        submit.bidCurrency.should.equal 'BTC'
        submit.offerCurrency.should.equal 'EUR'
        submit.bidPrice.compareTo(new Amount '100').should.equal 0
        submit.bidAmount.compareTo(new Amount '50').should.equal 0
        result = delta.result
        result.lockedFunds.compareTo(new Amount '5000').should.equal 0
        result.trades.should.have.length 1
        resultReceived.resolve()
      fourthDelta = (message) =>
        delta = new Delta 
          json: message
        delta.sequence.should.equal 3
        operation = delta.operation
        operation.sequence.should.equal 3
        operation.account.should.equal 'Peter'
        submit = operation.submit
        submit.bidCurrency.should.equal 'BTC'
        submit.offerCurrency.should.equal 'EUR'
        submit.bidPrice.compareTo(new Amount '100').should.equal 0
        submit.bidAmount.compareTo(new Amount '50').should.equal 0
        result = delta.result
        result.lockedFunds.compareTo(new Amount '5000').should.equal 0
        result.trades.should.have.length 1
        deltaReceived.resolve()        
      thirdResult = (message) =>
        response = JSON.parse message
        operation = new Operation
          exported: response.operation
        operation.sequence.should.equal 2
        operation.account.should.equal 'Peter'
        submit = operation.submit
        submit.bidCurrency.should.equal 'EUR'
        submit.offerCurrency.should.equal 'BTC'
        submit.offerPrice.compareTo(new Amount '100').should.equal 0
        submit.offerAmount.compareTo(new Amount '50').should.equal 0
        delta = new Delta 
          exported: response.delta
        delta.sequence.should.equal 2
        operation = delta.operation
        operation.sequence.should.equal 2
        operation.account.should.equal 'Peter'
        submit = operation.submit
        submit.bidCurrency.should.equal 'EUR'
        submit.offerCurrency.should.equal 'BTC'
        submit.offerPrice.compareTo(new Amount '100').should.equal 0
        submit.offerAmount.compareTo(new Amount '50').should.equal 0
        result = delta.result
        result.lockedFunds.compareTo(new Amount '50').should.equal 0
        result.trades.should.deep.equal []
        @ceOperationHub.result.removeListener 'message', thirdResult
        @ceOperationHub.result.on 'message', fourthResult
      thirdDelta = (message) =>
        delta = new Delta 
          json: message
        delta.sequence.should.equal 2
        operation = delta.operation
        operation.sequence.should.equal 2
        operation.account.should.equal 'Peter'
        submit = operation.submit
        submit.bidCurrency.should.equal 'EUR'
        submit.offerCurrency.should.equal 'BTC'
        submit.offerPrice.compareTo(new Amount '100').should.equal 0
        submit.offerAmount.compareTo(new Amount '50').should.equal 0
        result = delta.result
        result.lockedFunds.compareTo(new Amount '50').should.equal 0
        result.trades.should.deep.equal []
        @ceDeltaHub.stream.removeListener 'message', thirdDelta
        @ceDeltaHub.stream.on 'message', fourthDelta
      secondResult = (message) =>
        response = JSON.parse message
        operation = new Operation
          exported: response.operation
        operation.sequence.should.equal 1
        operation.account.should.equal 'Peter'
        deposit = operation.deposit
        deposit.currency.should.equal 'BTC'
        deposit.amount.compareTo(new Amount '50').should.equal 0
        delta = new Delta 
          exported: response.delta
        delta.sequence.should.equal 1
        operation = delta.operation
        operation.sequence.should.equal 1
        operation.account.should.equal 'Peter'
        deposit = operation.deposit
        deposit.currency.should.equal 'BTC'
        deposit.amount.compareTo(new Amount '50').should.equal 0
        result = delta.result
        result.funds.compareTo(new Amount '50').should.equal 0
        @ceOperationHub.result.removeListener 'message', secondResult
        @ceOperationHub.result.on 'message', thirdResult
      secondDelta = (message) =>
        delta = new Delta 
          json: message
        delta.sequence.should.equal 1
        operation = delta.operation
        operation.sequence.should.equal 1
        operation.account.should.equal 'Peter'
        deposit = operation.deposit
        deposit.currency.should.equal 'BTC'
        deposit.amount.compareTo(new Amount '50').should.equal 0
        result = delta.result
        result.funds.compareTo(new Amount '50').should.equal 0
        @ceDeltaHub.stream.removeListener 'message', secondDelta
        @ceDeltaHub.stream.on 'message', thirdDelta
      firstResult = (message) =>
        response = JSON.parse message
        operation = new Operation
          exported: response.operation
        operation.sequence.should.equal 0
        operation.account.should.equal 'Peter'
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.compareTo(new Amount '5000').should.equal 0
        delta = new Delta 
          exported: response.delta
        delta.sequence.should.equal 0
        operation = delta.operation
        operation.sequence.should.equal 0
        operation.account.should.equal 'Peter'
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.compareTo(new Amount '5000').should.equal 0
        result = delta.result
        result.funds.compareTo(new Amount '5000').should.equal 0
        @ceOperationHub.result.removeListener 'message', firstResult
        @ceOperationHub.result.on 'message', secondResult
      firstDelta = (message) =>
        delta = new Delta 
          json: message
        delta.sequence.should.equal 0
        operation = delta.operation
        operation.sequence.should.equal 0
        operation.account.should.equal 'Peter'
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.compareTo(new Amount '5000').should.equal 0
        result = delta.result
        result.funds.compareTo(new Amount '5000').should.equal 0
        @ceDeltaHub.stream.removeListener 'message', firstDelta
        @ceDeltaHub.stream.on 'message', secondDelta
      @ceOperationHub.result.on 'message', firstResult
      @ceDeltaHub.stream.on 'message', firstDelta
      # wait for sockets to open and connect in case everything is going too quick
      setTimeout =>
        @ceOperationHub.stream.send JSON.stringify @depositOperation1
        @ceOperationHub.stream.send JSON.stringify @depositOperation2
        @ceOperationHub.stream.send JSON.stringify @submitOperation1
        @ceOperationHub.stream.send JSON.stringify @submitOperation2
      , 100

    it 'should error on operations with IDs that have already been executed', (done) ->
      secondResult = (message) =>
        response = JSON.parse message
        response.error.should.equal 'Error: Unexpected sequence number'
        operation = new Operation
          exported: response.operation
        operation.sequence.should.equal 0
        operation.account.should.equal 'Peter'
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.compareTo(new Amount '5000').should.equal 0
        done()
      firstResult = (message) =>
        response = JSON.parse message
        operation = new Operation
          exported: response.operation
        operation.sequence.should.equal 0
        operation.account.should.equal 'Peter'
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.compareTo(new Amount '5000').should.equal 0
        delta = new Delta 
          exported: response.delta
        delta.sequence.should.equal 0
        operation = delta.operation
        operation.sequence.should.equal 0
        operation.account.should.equal 'Peter'
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.compareTo(new Amount '5000').should.equal 0
        result = delta.result
        result.funds.compareTo(new Amount '5000').should.equal 0
        @ceOperationHub.result.removeListener 'message', firstResult
        @ceOperationHub.result.on 'message', secondResult
      @ceOperationHub.result.on 'message', firstResult
      # wait for sockets to open and connect in case everything is going too quick
      setTimeout =>
        @ceOperationHub.stream.send JSON.stringify @depositOperation1
        @ceOperationHub.stream.send JSON.stringify @depositOperation1
      , 100      

    it 'should error on operations with IDs that are not consecutive', (done) ->
      @ceOperationHub.result.on 'message', (message) =>
        response = JSON.parse message
        response.error.should.equal 'Error: Unexpected sequence number'
        operation = new Operation
          exported: response.operation
        operation.sequence.should.equal 1
        operation.account.should.equal 'Peter'
        deposit = operation.deposit
        deposit.currency.should.equal 'BTC'
        deposit.amount.compareTo(new Amount '50').should.equal 0
        done()
      # wait for sockets to open and connect in case everything is going too quick
      setTimeout =>
        @ceOperationHub.stream.send JSON.stringify @depositOperation2
      , 100      

    it.skip 'should be up to date with operations from the ce-operation-hub and provide the current state to the ce-delta-hub instance', (done) ->
      done()
