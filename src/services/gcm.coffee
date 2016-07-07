gcm = require 'node-gcm'
Q = require 'q'
genrun = require 'q-genrun'


GOOGLE_API_KEY = "" or process.env.GOOGLE_API_KEY
delete process.env.GOOGLE_API_KEY # nobody needs to know

sender = new gcm.Sender(GOOGLE_API_KEY);
sender.send = Q.denodeify(sender.send.bind(sender))

invalidateToken = ->


# exported api

module.exports.send = send = (notification={}, tokens=[]) -> genrun ->
  try
    data =
      message: notification.alert or notification.message
    # tell GCM servers we don't actually want to send the message
    data.dryRun = true if process.env.TEST_MODE in ["1", "true"]

    message = new gcm.Message({data})

    response = yield sender.send(message, {registrationTokens: tokens})
    console.log "GCM Service Notification Sent", response

    # check if some device tokens are not valid anymore
    deviceTokensToDelete = []
    if response.results
      for result, index in response.results
        if result.error is 'InvalidRegistration'
          deviceTokensToDelete.push(tokens[index])
    console.log "GCM Service Invalid tokens", deviceTokensToDelete if deviceTokensToDelete.length > 0
    invalidateToken(token) for token in deviceTokensToDelete

    return response
  catch error
    console.log "GCM Service Error", error
    throw error

module.exports.setInvalidTokenCallback = (cb) -> invalidateToken = cb


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
