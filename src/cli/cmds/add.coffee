genrun = require 'q-genrun'

{ pushService, quit } = require '../common'

module.exports =
  command: 'add <username> <userid> <type> <token>'
  describe: 'add one device token'
  builder: (yargs) -> yargs
  handler: ({username, userid, type, token}) -> genrun ->
    try
      body =
        token:
          type: type
          value: token
        user:
          id: userid
          username: username
      console.log yield pushService('createOrUpdate', body, false)
    catch error
      console.log error, error.stack.split('\n') if error.stack

    yield quit()
