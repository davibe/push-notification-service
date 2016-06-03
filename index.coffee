amqp = require 'amqp-as-promised'
genrun = require 'q-genrun'
assert = require 'assert'


conf =
  connection:
    url: process.env.RABBITMQ_URL or "amqp://localhost:5672//?heartbeat=10"
  logLevel: 'warn'

amqpc = amqp(conf)


validate = (note) ->
  assert(
    note.tokens,
    'Notification has no destinations (tokens)'
  )
  assert(
    note.badge or note.message or note.alert,
    'Notification is empty (no alert, message, badge)'
  )
  assert(
    note.type in ['apn', 'gcm'],
    "Notification type unknown (#{note.type} is not [apn|gcn])"
  )


serve = (msg, headers, del) -> genrun ->
  try
    validate(msg)
    yield console.log 'PushNotification Service should now serve message', msg

  catch error # log and re-throw the error back to the amqp producer
    console.log 'PushNotification service error', error
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
