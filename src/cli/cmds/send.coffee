genrun = require 'q-genrun'

{ pushService, quit } = require '../common'

module.exports =
  command: 'send <type> <token> <badge> <message>'
  describe: 'send notification to one device token'
  builder: (yargs) -> yargs
  handler: ({type, token, badge, message}) -> genrun ->
    try
      note =
        tokens: if token then [token] else []
        type: type
        notification:
          badge: badge
          alert: message
      console.log 'Sending notification', note
      response = yield pushService('send', note)
      console.log response
    catch error
      console.log error, error.stack.split('\n') if error.stack

    yield quit()
