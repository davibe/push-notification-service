amqp = require 'amqp-as-promised'
genrun = require 'q-genrun'
assert = require 'assert'

gcm = require './gcm'
apn = require './apn'

conf =
  connection:
    url: process.env.RABBITMQ_URL or "amqp://localhost:5672//?heartbeat=10"
  logLevel: 'warn'

amqpc = amqp(conf)


serviceForType = (type) -> if type is 'gcm' then gcm else apn


validate = (msg) ->
  assert(
    msg.tokens,
    'Notification has no destinations (tokens)'
  )
  assert(
    msg.notification.badge or msg.notification.message or msg.notification.alert,
    'Notification is empty (no alert, message, badge)'
  )
  assert(
    msg.type in ['apn', 'gcm'],
    "Notification type unknown (#{msg.type} is not [apn|gcm])"
  )


serve = (msg, headers, del) -> genrun ->
  try
    validate(msg)
    service = serviceForType(msg.type)
    yield service.send(msg.notification, msg.tokens)

  catch error # log and re-throw the error back to the amqp producer
    console.log 'PushNotification service error', error
    console.log error.stack.split('\n') if error.stack
    throw error

  { result: 'ok' }


if not module.parent

  options = { ack: true, prefetchCount: 1 }
  amqpc.serve 'myexchange', 'push-notification-service', options, serve

  gracefulShutdown = (opts) ->
      console.log 'PushNotification service shutting down'
      amqpc.shutdown().then ->
          process.exit 0

  process.on 'SIGINT', gracefulShutdown
  process.on 'SIGTERM', gracefulShutdown
