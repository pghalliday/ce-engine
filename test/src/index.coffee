chai = require 'chai'
chai.should()
expect = chai.expect

ChildDaemon = require 'child-daemon'
zmq = require 'zmq'
Q = require 'q'

describe 'ce-engine', ->
  it 'should take parameters from a file', (done) ->
    this.timeout 5000
    ceOperationHub = 
      stream: zmq.socket 'pub'
      result: zmq.socket 'pull'
    ceDeltaHub = 
      stream: zmq.socket 'pull'
    depositOperation =
      account: 'Peter'
      id: 0     
      deposit:
        currency: 'EUR'
        amount: '5000'
    ceOperationHub.stream.bindSync 'tcp://*:7000'
    ceOperationHub.result.bindSync 'tcp://*:7001'
    ceDeltaHub.stream.bindSync 'tcp://*:7002'
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
        done()
    , done)
    .done()
    childDaemon.start (error, matched) =>
      expect(error).to.not.be.ok
      ceOperationHub.result.on 'message', (message) =>
        operation = JSON.parse message
        operation.account.should.equal 'Peter'
        operation.id.should.equal 0
        operation.result.should.equal 'success'
        deposit = operation.deposit
        deposit.currency.should.equal 'EUR'
        deposit.amount.should.equal '5000'
        statusReceived.resolve()
      ceDeltaHub.stream.on 'message', (message) =>
        delta = JSON.parse message
        delta.id.should.equal 0
        increase = delta.increase
        increase.account.should.equal 'Peter'
        increase.currency.should.equal 'EUR'
        increase.amount.should.equal '5000'
        deltaReceived.resolve()
      # wait for sockets to open and connect in case everything is going too quick
      setTimeout =>
        ceOperationHub.stream.send JSON.stringify depositOperation
      , 100
