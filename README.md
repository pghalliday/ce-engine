ce-engine
=========

[![Build Status](https://travis-ci.org/pghalliday/ce-engine.png?branch=master)](https://travis-ci.org/pghalliday/ce-engine)
[![Dependency Status](https://gemnasium.com/pghalliday/ce-engine.png)](https://gemnasium.com/pghalliday/ce-engine)

Currency exchange order matching engine.

## Configuration

configuration should be placed in a file called `config.json` in the root of the project

```javascript
{
  // Deposits commission payments into this account ID
  "commission": {
    "account": "commission"
  },
  // Connects to a ce-operation-hub to receive sequential operations and push the results
  "ce-operation-hub": {
    "host": "localhost",
    // Port for 0MQ `sub` socket 
    "stream": 7000,
    // Port for 0MQ `push` socket 
    "result": 7001    
  },
  // Connects to a ce-delta-hub to respond to state requests and stream sequential market state deltas
  "ce-delta-hub": {
    "host": "localhost",
    // Port for 0MQ `push` socket 
    "stream": 7002,
    // Port for 0MQ `router` socket 
    "state": 7003
  }
}
```

## Starting and stopping the server

Forever is used to keep the server running as a daemon and can be called through npm as follows

```
$ npm start
$ npm stop
```

Output will be logged to the following files

- `~/.forever/forever.log` Forever output
- `./out.log` stdout
- `./err.log` stderr

## Roadmap

- persist market state (database?)
  - catch up on missed operations
- maintain a history of deltas
  - since last persisted market state
- persist deltas (database?)

### Operations

### `withdraw`

Withdraw funds from an account balance

```javascript
{
  "reference": "550e8400-e29b-41d4-a716-446655440000",
  "account": "[account]",
  "sequence": 1234567890,
  "timestamp": 1371737390976,
  "withdraw": {
    "currency": "EUR",
    "amount": "5000"
  }
}
```

result:

```javascript
{
  "reference": "550e8400-e29b-41d4-a716-446655440000",
  "account": "[account]",
  "sequence": 1234567890,
  "timestamp": 1371737390976,
  "result": "success",
  "withdraw": {
    "currency": "EUR",
    "amount": "5000"
  }
}
```

Can result in the following deltas:

- `withdraw`

### `cancel`

Remove an order from an order book

```javascript
{
  "reference": "550e8400-e29b-41d4-a716-446655440000",
  "account": "[account]",
  "sequence": 1234567890,
  "timestamp": 1371737390976,
  "cancel": {
    "sequence": 9876543210
  }
}
```

result:

```javascript
{
  "reference": "550e8400-e29b-41d4-a716-446655440000",
  "account": "[account]",
  "sequence": 1234567890,
  "timestamp": 1371737390976,
  "result": "success",
  "cancel": {
    "sequence": 9876543210
  }
}
```

Can result in the following deltas:

- `cancel`

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Test your code using: 

```
$ npm test
```

### Using Vagrant
To use the Vagrantfile you will also need to install the following vagrant plugins

```
$ vagrant plugin install vagrant-omnibus
$ vagrant plugin install vagrant-berkshelf
```

The cookbook used by vagrant is located in a git submodule so you will have to intialise that after cloning

```
$ git submodule init
$ git submodule update
```

## License
Copyright &copy; 2013 Peter Halliday  
Licensed under the MIT license.
