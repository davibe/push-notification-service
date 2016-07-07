path = require 'path'
apn = require 'apn'


CERTS_PATH = process.env.CERTS_PATH or 'push-notification-service-data'
delete process.env.CERTS_PATH # nobody else needs to know
ENV = 'development'
ENV = 'production' if process.env.NODE_ENV is 'production'

# APN P12 certificate are created like this
# https://github.com/argon/node-apn/wiki/Preparing-Certificates

options =
  pfx: path.join(CERTS_PATH,'apn', ENV,  'key.p12')
  production: ENV is 'production'
  batchFeedback: true

# Handle feedback, tells us when devicetokens are invalid

feedback = new apn.Feedback(options)

feedback.on 'feedback', (devices) ->
  deviceTokensToDelete = (item.device for item in devices)
  console.log "APN Service Invalid tokens", deviceTokensToDelete if deviceTokensToDelete.length > 0

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

service.on 'transmissionError', (errCode, notification, device) ->
  token = device.token.toString('hex')
  console.log "APN Service Notification to #{token} failed with #{errCode}", device, notification

service.on 'cacheTooSmall', (sizeDifference) ->
  console.log "APN Service Error: CacheTooSmall (size difference: #{sizeDifference})"


# exported api

module.exports.send = send = (notification={}, tokens=[]) ->
  note = new apn.Notification()
  # expiry
  oneHour = Math.floor(Date.now() / 1000) + 3600
  fiveHours = oneHour * 5
  note.expry = fiveHours
  # badge increment
  # TODO: figure out how to do autoincrementinb badge
  note.badge = notification.badge or 1
  # the message to be shown to the user
  note.alert = notification.alert or notification.message or ""
  # additional application-specific payload
  note.payload = notification.payload || {}

  if process.env.TEST_MODE in ["1", "true"]
    return console.log "Would send APN push notification", note, tokens

  service.pushNotification(note, tokens)


# TODO: setup feedback service
# Do we actually need feedback service if we already have 'transmissionError' event ?

# cli test usage
if not module.parent
  # create and send message
  token = process.argv[2]
  message = process.argv[3] || "io non sono te"

  send({message}, [token])
  console.log "=> #{token}: #{message}"
