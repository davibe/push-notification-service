genrun = require 'q-genrun'

{ pushService, quit } = require '../common'

module.exports =
  command: 'list-with-username <username>'
  describe: 'list token of a user identified by username'
  builder: (yargs) -> yargs
  handler: ({username}) -> genrun ->
    try
      res = yield pushService('findByUsername', username)
      console.log JSON.stringify(res, null, 2)
    catch error
      console.log error, error.stack.split('\n') if error.stack

    yield quit()
