genrun = require 'q-genrun'

{ pushService, quit } = require '../common'

module.exports =
  command: 'del <token>'
  describe: 'delete one device token'
  builder: (yargs) -> yargs
  handler: ({token}) -> genrun ->
    try
      console.log yield pushService('deleteById', token, null)
    catch error
      console.log error, error.stack.split('\n') if error.stack

    yield quit()
