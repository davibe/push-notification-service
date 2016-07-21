genrun = require 'q-genrun'

{ pushService, quit } = require '../common'
send = require('./send').handler

module.exports =
  command: 'send-with-username <username> <badge> <message>'
  describe: 'send notification to one user'
  builder: (yargs) -> yargs
  handler: ({username, badge, message}) -> genrun ->
    try
      tokens = yield pushService('findByUsername', username)
      for item in tokens
        token = item.token.value
        type = item.token.type
        yield send({token, type, badge, message})
    catch error
      console.log error, error.stack.split('\n') if error.stack

    yield quit()
