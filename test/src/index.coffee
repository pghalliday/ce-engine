chai = require 'chai'
chai.should()
expect = chai.expect

ChildDaemon = require 'child-daemon'
zmq = require 'zmq'
Q = require 'q'

Operation = require('currency-market').Operation
Delta = require('currency-market').Delta
Amount = require('currency-market').Amount

describe 'ce-engine', ->
  it 'should take parameters from a file', (done) ->
    this.timeout 5000
    ceOperationHub = 
      stream: zmq.socket 'pub'
      result: zmq.socket 'pull'
    ceDeltaHub = 
      stream: zmq.socket 'pull'
      state: zmq.socket 'dealer'
    depositOperation = new Operation
      reference: '550e8400-e29b-41d4-a716-446655440000'
      account: 'Peter'
      deposit:
        currency: 'EUR'
        amount: new Amount '5000'
    depositOperation.accept
      sequence: 0
      timestamp: Date.now()
    ceOperationHub.stream.bindSync 'tcp://*:7000'
    ceOperationHub.result.bindSync 'tcp://*:7001'
    ceDeltaHub.stream.bindSync 'tcp://*:7002'
    ceDeltaHub.state.bindSync 'tcp://*:7003'
    childDaemon = new ChildDaemon 'node', [
      'lib/src/index.js',
      '--config',
      'test/support/testConfig.json'
    ], new RegExp 'ce-engine started'
    statusReceived = Q.defer()
    deltaReceived = Q.defer()
    Q.all([
      statusReceived.promise,
      deltaReceived.promise
    ])
    .then((results) =>
      childDaemon.stop (error) =>
        expect(error).to.not.be.ok
        ceOperationHub.stream.close()
        ceOperationHub.result.close()
        ceDeltaHub.stream.close()
        ceDeltaHub.state.close()
        done()
    , done)
    .done()
    childDaemon.start (error, matched) =>
      expect(error).to.not.be.ok
      ceOperationHub.result.on 'message', (message) =>
        response = JSON.parse message
        operation = new Operation
          exported: response.operation
        operation.account.should.equal 'Peter'
        operation.sequence.should.equal 0
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.compareTo(new Amount '5000').should.equal 0
        delta = new Delta 
          exported: response.delta
        delta.sequence.should.equal 0
        operation = delta.operation
        operation.account.should.equal 'Peter'
        operation.sequence.should.equal 0
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.compareTo(new Amount '5000').should.equal 0
        result = delta.result
        result.funds.compareTo(new Amount '5000').should.equal 0
        statusReceived.resolve()
      ceDeltaHub.stream.on 'message', (message) =>
        delta = new Delta 
          json: message
        delta.sequence.should.equal 0
        operation = delta.operation
        operation.account.should.equal 'Peter'
        operation.sequence.should.equal 0
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.compareTo(new Amount '5000').should.equal 0
        result = delta.result
        result.funds.compareTo(new Amount '5000').should.equal 0
        deltaReceived.resolve()
      # wait for sockets to open and connect in case everything is going too quick
      setTimeout =>
        ceOperationHub.stream.send JSON.stringify depositOperation
      , 100
