assert = require 'assert'
Q = require 'q-extended'
amqp = require 'amqp-as-promised'

service = require '../src/service'
dbTest = require('./db').test

conf =
  connection:
    url: process.env.RABBITMQ_URL or "amqp://localhost:5672//?heartbeat=10"
  logLevel: 'warn'
amqpc = amqp(conf)

pushService = (method, args...) ->
  amqpc.rpc('myexchange', "push-notification-service.#{method}", args)

describe 'amqp db interface should work as well', ->
  # prepare amqp client

  before -> Q.genrun ->
    yield service.start()

  # launch db tests using but passing it a remote rpc interface
  dbTest({
    createOrUpdate: (args...) -> pushService('createOrUpdate', args...)
    findByUserId: (args...) -> pushService('findByUserId', args...)
    deleteByUserId: (args...) -> pushService('deleteByUserId', args...)
    deleteById: (args...) -> pushService('deleteById', args...)
    getById: (args...) -> pushService('getById', args...)
  })


sample =
  user:
    id: 'sample_id'
    username: 'sample_username'
  token:
    type: 'apn'
    value: 'SAMPLE_TOKEN'

tokens = [sample.token.value]


describe '.. and be able to send messages !', ->

  afterEach -> Q.genrun ->
    try
      yield pushService('deleteById', sample.token.value)
    catch e

  it "saves one push token with no errors", -> Q.genrun ->
    yield pushService('createOrUpdate', sample)

    notificationApn =
      tokens: [sample.token.value]
      type: 'apn'
      notification:
        alert: 'this is a message'

    yield pushService('send', notificationApn)
