chai = require 'chai'
chai.should()
expect = chai.expect

Server = require '../../src/Server'

zmq = require 'zmq'
ports = require '../support/ports'

describe 'Server', ->
  describe '#stop', ->
    it 'should not error if the server has not been started', (done) ->
      server = new Server
        'ce-operation-hub':
          host: 'localhost'
          stream: ports()
          result: ports()
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
      @order =
        account: 'Peter'
        bidCurrency: 'EUR'
        offerCurrency: 'BTC'
        bidPrice: '100'
        bidAmount: '50'
        id: 0     
      @server = new Server
        'ce-operation-hub':
          host: 'localhost'
          stream: ceOperationHubStreamPort
          result: ceOperationHubResultPort
      @server.start done

    afterEach (done) ->
      @server.stop =>
        @ceOperationHub.stream.close()
        @ceOperationHub.result.close()
        done()

    it 'should push a status of success for published orders', (done) ->
      @ceOperationHub.result.on 'message', (message) =>
        order = JSON.parse message
        order.account.should.equal 'Peter'
        order.bidCurrency.should.equal 'EUR'
        order.offerCurrency.should.equal 'BTC'
        order.bidPrice.should.equal '100'
        order.bidAmount.should.equal '50'
        order.id.should.equal 0
        order.status.should.equal 'success'
        done()
      # wait for sockets to open and connect in case everything is going too quick
      setTimeout =>
        @ceOperationHub.stream.send JSON.stringify @order
      , 100
