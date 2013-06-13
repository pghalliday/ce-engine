chai = require 'chai'
chai.should()
expect = chai.expect

Server = require '../../src/Server'

zmq = require 'zmq'

describe 'Server', ->
  describe '#stop', ->
    it 'should not error if the server has not been started', (done) ->
      server = new Server
        ceOperationHubSubscriber: 'tcp://localhost:8000'
        ceOperationHubPush: 'tcp://localhost:8001'
      server.stop (error) ->
        expect(error).to.not.be.ok
        done()

  describe '#start', ->
    it 'should start and be stoppable', (done) ->
      server = new Server
        ceOperationHubSubscriber: 'tcp://localhost:8000'
        ceOperationHubPush: 'tcp://localhost:8001'
      server.start (error) ->
        expect(error).to.not.be.ok
        server.stop (error) ->
          expect(error).to.not.be.ok
          done()

  describe 'when started', ->
    beforeEach (done) ->
      @ceOperationHubPublisher = zmq.socket 'pub'
      @ceOperationHubPublisher.bindSync 'tcp://*:8000'
      @ceOperationHubPull = zmq.socket 'pull'
      @ceOperationHubPull.bindSync 'tcp://*:8001'
      @order =
        account: 'Peter'
        bidCurrency: 'EUR'
        offerCurrency: 'BTC'
        bidPrice: '100'
        bidAmount: '50'
        id: 0     
      @server = new Server
        ceOperationHubSubscriber: 'tcp://localhost:8000'
        ceOperationHubPush: 'tcp://localhost:8001'
      @server.start done

    afterEach (done) ->
      @server.stop =>
        @ceOperationHubPublisher.close()
        @ceOperationHubPull.close()
        done()

    it 'should push a status of success for published orders', (done) ->
      @ceOperationHubPull.on 'message', (message) =>
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
        @ceOperationHubPublisher.send JSON.stringify @order
      , 100
