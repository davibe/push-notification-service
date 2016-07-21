genrun = require 'q-genrun'

{ pushService, quit } = require '../common'

module.exports =
  command: 'list <userId>'
  describe: 'list token of a user identified by id'
  builder: (yargs) -> yargs
  handler: ({userId}) -> genrun ->
    try
      res = yield pushService('findByUserId', userId)
      console.log JSON.stringify(res, null, 2)
    catch error
      console.log error, error.stack.split('\n') if error.stack

    yield quit()
