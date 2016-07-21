path = require 'path'
apn = require 'apn'


CERTS_PATH = process.env.CERTS_PATH or 'push-notification-service-data'
delete process.env.CERTS_PATH # nobody else needs to know
ENV = 'development'
ENV = 'production' if process.env.NODE_ENV is 'production'

# APN certificates are created like this
# https://github.com/argon/node-apn/wiki/Preparing-Certificates

cert = path.join(CERTS_PATH, 'apn', ENV,  'cert.pem')
key = path.join(CERTS_PATH, 'apn', ENV,  'key.pem')

options =
  cert: cert
  key: key
  production: ENV is 'production'
  batchFeedback: true
  interval: 10

invalidateToken = ->

# Handle feedback, tells us when devicetokens are invalid

feedback = new apn.Feedback(options)

feedback.on 'feedback', (devices) ->
  console.log 'feedback', devices
  deviceTokensToDelete = (item.device.token.toString("hex") for item in devices)
  console.log "APN Service Feedback Invalid tokens", deviceTokensToDelete if deviceTokensToDelete.length > 0
  invalidateToken(token) for token in deviceTokensToDelete

# Create the main service

service = new apn.Connection(options)

# log all events

service.on 'connected', ->
  console.log 'APN Service is not connected'

service.on 'socketError', (e) ->
  console.log 'APN Service Socket error', e

service.on 'error', (e) ->
  console.log 'APN Service Error', e

service.on 'timeout', (e) ->
  console.log 'APN Service connection timed out'

service.on 'transmitted', (notification, device) ->
  if ENV is 'production' then return
  token = device.token.toString('hex')
  console.log "APN Service Notification transmitted to: #{token}"

service.on 'transmissionError', (errCode, notification, token) ->
  console.log "APN Service Notification to #{token} failed with #{errCode}", token, notification

service.on 'cacheTooSmall', (sizeDifference) ->
  console.log "APN Service Error: CacheTooSmall (size difference: #{sizeDifference})"


# exported api

module.exports.send = send = (notification={}, tokens=[]) ->
  ret = { result: 'ok' } # we have no specific payload to return

  note = new apn.Notification()
  # expiry
  oneHour = Math.floor(Date.now() / 1000) + 3600
  fiveHours = oneHour * 5
  aMinute = Math.floor(Date.now() / 1000) + 60
  note.expry = aMinute
  # badge increment
  # TODO: figure out how to do autoincrementinb badge
  note.badge = notification.badge or ""
  # the message to be shown to the user
  note.alert = notification.alert or notification.message or ""
  # additional application-specific payload
  note.payload = notification.payload || {}

  if process.env.TEST_MODE in ["1", "true"]
    console.log "Would send APN push notification", note, tokens
    return ret

  service.pushNotification(note, tokens)
  ret

module.exports.setInvalidTokenCallback = (cb) -> invalidateToken = cb

# TODO: setup feedback service
# Do we actually need feedback service if we already have 'transmissionError' event ?

# cli test usage
if not module.parent
  # create and send message
  token = process.argv[2]
  message = process.argv[3] || "io non sono te"

  send({message}, [token])
  console.log "=> #{token}: #{message}"
