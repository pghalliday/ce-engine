chai = require 'chai'
chai.should()
expect = chai.expect

ChildDaemon = require 'child-daemon'
zmq = require 'zmq'

describe 'ce-engine', ->
  describe 'on start', ->
    beforeEach ->
      @ceOperationHubPublisher = zmq.socket 'pub'
      @ceOperationHubPull = zmq.socket 'pull'
      @order =
        account: 'Peter'
        bidCurrency: 'EUR'
        offerCurrency: 'BTC'
        bidPrice: '100'
        bidAmount: '50'
        id: 0     

    afterEach ->
      @ceOperationHubPublisher.close()
      @ceOperationHubPull.close()

    it 'should take parameters from the command line', (done) ->
      this.timeout 5000
      @ceOperationHubPublisher.bindSync 'tcp://*:6000'
      @ceOperationHubPull.bindSync 'tcp://*:6001'
      childDaemon = new ChildDaemon 'node', [
        'lib/src/index.js',
        '--ce-operation-hub-subscriber',
        'tcp://localhost:6000',
        '--ce-operation-hub-push',
        'tcp://localhost:6001',
      ], new RegExp 'ce-engine started'
      childDaemon.start (error, matched) =>
        expect(error).to.not.be.ok
        @ceOperationHubPull.on 'message', (message) =>
          order = JSON.parse message
          order.account.should.equal 'Peter'
          order.bidCurrency.should.equal 'EUR'
          order.offerCurrency.should.equal 'BTC'
          order.bidPrice.should.equal '100'
          order.bidAmount.should.equal '50'
          order.id.should.equal 0
          order.status.should.equal 'success'
          childDaemon.stop (error) =>
            expect(error).to.not.be.ok
            done()
        @ceOperationHubPublisher.send JSON.stringify @order

    it 'should take parameters from a file', (done) ->
      this.timeout 5000
      @ceOperationHubPublisher.bindSync 'tcp://*:7000'
      @ceOperationHubPull.bindSync 'tcp://*:7001'
      childDaemon = new ChildDaemon 'node', [
        'lib/src/index.js',
        '--config',
        'test/support/testConfig.json'
      ], new RegExp 'ce-engine started'
      childDaemon.start (error, matched) =>
        expect(error).to.not.be.ok
        @ceOperationHubPull.on 'message', (message) =>
          order = JSON.parse message
          order.account.should.equal 'Peter'
          order.bidCurrency.should.equal 'EUR'
          order.offerCurrency.should.equal 'BTC'
          order.bidPrice.should.equal '100'
          order.bidAmount.should.equal '50'
          order.id.should.equal 0
          order.status.should.equal 'success'
          childDaemon.stop (error) =>
            expect(error).to.not.be.ok
            done()
        @ceOperationHubPublisher.send JSON.stringify @order

    it 'should override parameters from a file with parameters from the command line', (done) ->
      this.timeout 5000
      @ceOperationHubPublisher.bindSync 'tcp://*:8000'
      @ceOperationHubPull.bindSync 'tcp://*:8001'
      childDaemon = new ChildDaemon 'node', [
        'lib/src/index.js',
        '--config',
        'test/support/testConfig.json',
        '--ce-operation-hub-subscriber',
        'tcp://localhost:8000',
        '--ce-operation-hub-push',
        'tcp://localhost:8001',
      ], new RegExp 'ce-engine started'
      childDaemon.start (error, matched) =>
        expect(error).to.not.be.ok
        @ceOperationHubPull.on 'message', (message) =>
          order = JSON.parse message
          order.account.should.equal 'Peter'
          order.bidCurrency.should.equal 'EUR'
          order.offerCurrency.should.equal 'BTC'
          order.bidPrice.should.equal '100'
          order.bidAmount.should.equal '50'
          order.id.should.equal 0
          order.status.should.equal 'success'
          childDaemon.stop (error) =>
            expect(error).to.not.be.ok
            done()
        @ceOperationHubPublisher.send JSON.stringify @order
