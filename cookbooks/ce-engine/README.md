cookbook-ce-engine
==================

Chef cookbook to install and start a ce-engine instance

## Depends

- nodejs
- git
- zeromq (https://github.com/pghalliday/cookbook-zeromq.git)

## Attributes

Attributes are specified under the `ce_engine` keyspace.

- `node[:ce_engine][:repository]` - the Git repository to install `ce-engine` from (defaults to "https://github.com/pghalliday/ce-engine.git")
- `node[:ce_engine][:destination]` - the directory to install `ce-engine` to (defaults to "/opt/ce-engine")
- `node[:ce_engine][:user]` - the user to install and start `ce-engine` as (defaults to "ce-engine")
- `node[:ce_engine][:commission][:account]` - the account ID to deposit commission payments to (defaults to "commission")
- `node[:ce_engine][:ce_operation_hub][:host]` - the hostname of the `ce-operation-hub` instance (defaults to "localhost")
- `node[:ce_engine][:ce_operation_hub][:stream]` - the port the `ce-engine` will use to subscribe to operations from the `ce-operation-hub` instance (defaults to "4001")
- `node[:ce_engine][:ce_operation_hub][:result]` - the port the `ce-engine` will use to push operation results to the `ce-operation-hub` instance (defaults to "4002")
- `node[:ce_engine][:ce_delta_hub][:host]` - the hostname of the ce-delta-hub instance (defaults to "localhost")
- `node[:ce_engine][:ce_delta_hub][:stream]` - the port the `ce-engine` will use to stream deltas to the `ce-delta-hub` instance (defaults to "5002")
- `node[:ce_engine][:ce_delta_hub][:state]` - the port the `ce-engine` will use to respond to state requests from the `ce-delta-hub` instance (defaults to "5002")

## Recipes

### default

- Installs `ce-engine`
- Runs npm install to get dependencies
- Runs npm start to start the `ce-engine`

## License
Copyright &copy; 2013 Peter Halliday  
Licensed under the MIT license.
