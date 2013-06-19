ce-engine
=========

[![Build Status](https://travis-ci.org/pghalliday/ce-engine.png?branch=master)](https://travis-ci.org/pghalliday/ce-engine)
[![Dependency Status](https://gemnasium.com/pghalliday/ce-engine.png)](https://gemnasium.com/pghalliday/ce-engine)

Currency exchange order matching engine.

## Configuration

configuration should be placed in a file called `config.json` in the root of the project

```javascript
{
  // Connects to a ce-operation-hub to receive sequential operations and push the results
  "ce-operation-hub": {
    "host": "localhost",
    // Port for 0MQ `sub` socket 
    "stream": 7000,
    // Port for 0MQ `push` socket 
    "result": 7001    
  },
  // Connects to a ce-delta-hub to stream sequential market state deltas
  "ce-delta-hub": {
    "host": "localhost",
    // Port for 0MQ `push` socket 
    "stream": 7002
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

## API

The following operations are supported

### `deposit`

```javascript
{
  "account": "[account]",
  "id": "1234567890",
  "deposit": {
    "currency": "EUR",
    "amount": "5000"
  }
}
```

result:

```javascript
{
  "account": "[account]",
  "id": "1234567890",
  "result": "success",
  "deposit": {
    "currency": "EUR",
    "amount": "5000"
  }
}
```

Can result in the following deltas:

- `deposit`

### `submit`

```javascript
{
  "account": "[account]",
  "id": "1234567890",
  "submit": {
    "bidCurrency": "BTC",
    "offerCurrency": "EUR",
    "bidPrice": "100",
    "bidAmount": "50"
  }
}
```

result:

```javascript
{
  "account": "[account]",
  "id": "1234567890",
  "result": "success",
  "order": {
    "bidCurrency": "BTC",
    "offerCurrency": "EUR",
    "bidPrice": "100",
    "bidAmount": "50"
  }
}
```

Can result in the following deltas:

- `submit` - resulting from the addition of the order
- `trade` - resulting from trades executed as a result of adding the order

## Roadmap

- integrate `currency-market` module
- persist market state (database?)
  - catch up on missed operations
- maintain a history of deltas
  - since last persisted market state
- persist deltas (database?)

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
