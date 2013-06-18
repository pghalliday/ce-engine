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
      ceDeltaHubStreamPort = ports()
      @ceDeltaHub.stream.bindSync 'tcp://*:' + ceDeltaHubStreamPort
      @unknownOperation =
        account: 'Peter'
        id: 0
        unknown:
          currency: 'BTC'
          amount: '50'
      @depositOperation =
        account: 'Peter'
        id: 0     
        deposit:
          currency: 'EUR'
          amount: '5000'
      @orderOperation =
        account: 'Peter'
        id: 0
        order:
          bidCurrency: 'EUR'
          offerCurrency: 'BTC'
          bidPrice: '100'
          bidAmount: '50'
      @server = new Server
        'ce-operation-hub':
          host: 'localhost'
          stream: ceOperationHubStreamPort
          result: ceOperationHubResultPort
        'ce-delta-hub':
          host: 'localhost'
          stream: ceDeltaHubStreamPort
      @server.start done

    afterEach (done) ->
      @server.stop =>
        @ceOperationHub.stream.close()
        @ceOperationHub.result.close()
        @ceDeltaHub.stream.close()
        done()

    it 'should push a result of unknown operation to the ce-operation-hub for published unknown operations', (done) ->
      @ceOperationHub.result.on 'message', (message) =>
        operation = JSON.parse message
        operation.account.should.equal 'Peter'
        operation.id.should.equal 0
        operation.result.should.equal 'unknown operation'
        unknown = operation.unknown
        unknown.currency.should.equal 'BTC'
        unknown.amount.should.equal '50'
        done()
      # wait for sockets to open and connect in case everything is going too quick
      setTimeout =>
        @ceOperationHub.stream.send JSON.stringify @unknownOperation
      , 100      

    it 'should push a result of success to the ce-operation-hub and push the balance increase delta to the ce-delta-hub for published deposits', (done) ->
      statusReceived = Q.defer()
      deltaReceived = Q.defer()
      Q.all([
        statusReceived.promise,
        deltaReceived.promise
      ])
      .then((results) =>
        done()
      , done)
      .done()
      @ceOperationHub.result.on 'message', (message) =>
        operation = JSON.parse message
        operation.account.should.equal 'Peter'
        operation.id.should.equal 0
        operation.result.should.equal 'success'
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.should.equal '5000'
        statusReceived.resolve()
      @ceDeltaHub.stream.on 'message', (message) =>
        delta = JSON.parse message
        delta.id.should.equal 0
        increase = delta.increase
        increase.account.should.equal 'Peter'
        increase.currency.should.equal 'EUR'
        increase.amount.should.equal '5000'
        deltaReceived.resolve()
      # wait for sockets to open and connect in case everything is going too quick
      setTimeout =>
        @ceOperationHub.stream.send JSON.stringify @depositOperation
      , 100

    it 'should push a result of success to the ce-operation-hub and push the order book delta to the ce-delta-hub for published orders', (done) ->
      statusReceived = Q.defer()
      deltaReceived = Q.defer()
      Q.all([
        statusReceived.promise,
        deltaReceived.promise
      ])
      .then((results) =>
        done()
      , done)
      .done()
      @ceOperationHub.result.on 'message', (message) =>
        operation = JSON.parse message
        operation.account.should.equal 'Peter'
        operation.id.should.equal 0
        operation.result.should.equal 'success'
        order = operation.order
        order.bidCurrency.should.equal 'EUR'
        order.offerCurrency.should.equal 'BTC'
        order.bidPrice.should.equal '100'
        order.bidAmount.should.equal '50'
        statusReceived.resolve()
      @ceDeltaHub.stream.on 'message', (message) =>
        delta = JSON.parse message
        delta.id.should.equal 0
        add = delta.add
        add.account.should.equal 'Peter'
        add.bidCurrency.should.equal 'EUR'
        add.offerCurrency.should.equal 'BTC'
        add.bidPrice.should.equal '100'
        add.bidAmount.should.equal '50'
        deltaReceived.resolve()
      # wait for sockets to open and connect in case everything is going too quick
      setTimeout =>
        @ceOperationHub.stream.send JSON.stringify @orderOperation
      , 100
