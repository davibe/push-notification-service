gcm = require 'node-gcm'
Q = require 'q'
genrun = require 'q-genrun'


GOOGLE_API_KEY = "" or process.env.GOOGLE_API_KEY
delete process.env.GOOGLE_API_KEY # nobody needs to know

sender = new gcm.Sender(GOOGLE_API_KEY);
sender.send = Q.denodeify(sender.send.bind(sender))


# exported api

module.exports.send = send = (notification={}, tokens=[]) -> genrun ->
  try
    data =
      message: notification.alert or notification.message
    message = new gcm.Message({data})

    if process.env.TEST_MODE in ["1", "true"]
      return console.log "Would send GCM push notification", message, tokens

    response = yield sender.send(message, {registrationTokens: tokens})
    console.log "GCM Service Notification Sent", response

    # check if some device tokens are not valid anymore
    deviceTokensToDelete = []
    if response.results
      for result, index in response.results
        if result.error is 'InvalidRegistration'
          deviceTokensToDelete.push(tokens[index])
    console.log "GCM Service Invalid tokens", deviceTokensToDelete if deviceTokensToDelete.length > 0

    return response
  catch error
    console.log "GCM Service Error", error
    throw error


if not module.parent then genrun ->
  try
    token = process.argv[2]
    message = process.argv[3] || "io non sono te"
    console.log "=> #{token}: #{message}"

    yield send({message}, [token])

  catch e
    # TODO: if send fails we may need to declare this token as invalid (?)
    console.log('error', e)
    console.log e
