assert = require 'assert'
Q = require 'q-extended'
amqp = require 'amqp-as-promised'

service = require '../src/service'
dbTest = require('./db').test

describe 'amqp db interface should work as well', ->
  # prepare amqp client
  conf =
    connection:
      url: process.env.RABBITMQ_URL or "amqp://localhost:5672//?heartbeat=10"
    logLevel: 'warn'
  amqpc = amqp(conf)

  before -> Q.genrun ->
    yield service.start()

  # launch db tests using but passing it a remote rpc interface
  dbTest({
    createOrUpdate: (args...) -> amqpc.rpc('myexchange', 'push-notification-service.createOrUpdate', args)
    findByUserId: (args...) -> amqpc.rpc('myexchange', 'push-notification-service.findByUserId', args)
    deleteByUserId: (args...) -> amqpc.rpc('myexchange', 'push-notification-service.deleteByUserId', args)
    deleteById: (args...) -> amqpc.rpc('myexchange', 'push-notification-service.deleteById', args)
    getById: (args...) -> amqpc.rpc('myexchange', 'push-notification-service.getById', args)
  })
