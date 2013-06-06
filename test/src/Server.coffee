chai = require 'chai'
chai.should()

Server = require '../../src/Server'

describe 'Server', ->
  it 'should instantiate', ->
    server = new Server()
    server.should.be.ok
