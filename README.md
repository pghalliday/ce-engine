ce-operation-hub
================

[![Build Status](https://travis-ci.org/pghalliday/ce-engine.png?branch=master)](https://travis-ci.org/pghalliday/ce-engine)
[![Dependency Status](https://gemnasium.com/pghalliday/ce-engine.png)](https://gemnasium.com/pghalliday/ce-engine)

Currency exchange order matching engine.

## Features

## Starting the server

```
$ npm start
```

## Roadmap

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
Copyright (c) 2013 Peter Halliday  
Licensed under the MIT license.
