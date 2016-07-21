amqp = require 'amqp-as-promised'
genrun = require 'q-genrun'

conf =
  connection:
    url: process.env.RABBITMQ_URL or "amqp://localhost:5672//?heartbeat=10"
  logLevel: 'warn'

amqpc = amqp(conf)


pushService = (method, args...) -> genrun ->
  yield amqpc.rpc('myexchange', "push-notification-service.#{method}", args)


quit = -> genrun ->
  yield amqpc.shutdown()
  process.exit()

module.exports = { pushService, quit }
