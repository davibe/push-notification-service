assert = require 'assert'
Q = require 'q-extended'
amqp = require 'amqp-as-promised'

esclient = require '../src/db/esclient'
db = require '../src/db'
service = require '../src/service'

sample =
  user:
    id: 'sample_id'
    username: 'sample_username'
  token:
    type: 'apn'
    value: 'SAMPLE_TOKEN'

describe 'amqp interface should work as well', ->
  # prepare amqp client
  conf =
    connection:
      url: process.env.RABBITMQ_URL or "amqp://localhost:5672//?heartbeat=10"
    logLevel: 'warn'
  amqpc = amqp(conf)

  # create a db instance that works remotely using amqp rpc func
  db = {}
  methods = ['createOrUpdate', 'findByUserId', 'deleteByUserId', 'deleteById', 'getById']
  for method in methods then do (method=method) ->
    db[method] = (args...) ->
      amqpc.rpc('myexchange', "push-notification-service.#{method}", args)

  before -> Q.genrun ->
    yield service.start()

  # delete the token after each test
  afterEach -> Q.genrun ->
    try
      yield db.deleteById(sample.token.value)
    catch e

  it "saves one push token with no errors", -> Q.genrun ->
    yield db.createOrUpdate(sample)

  it "gets the push token", -> Q.genrun ->
    yield db.createOrUpdate(sample)
    pushToken = yield db.getById(sample.token.value)
    expected = Object.assign({}, sample, {tsUpdated: pushToken.tsUpdated})
    assert.deepEqual(pushToken, expected)

  it "find token by user id", -> Q.genrun ->
    yield db.createOrUpdate(sample)
    pushTokens = yield db.findByUserId(sample.user.id)
    pushToken = pushTokens[0]
    expected = Object.assign({}, sample, {tsUpdated: pushToken.tsUpdated})
    assert.deepEqual(pushToken, expected)

  it "does not find token by wrong user id", -> Q.genrun ->
    yield db.createOrUpdate(sample)
    pushTokens = yield db.findByUserId(sample.user.id + "wrong")
    assert.equal(pushTokens.length, 0, 'Should not find any')

  it "find token by user ids", -> Q.genrun ->
    yield db.createOrUpdate(sample)
    pushTokens = yield db.findByUserId([sample.user.id])
    pushToken = pushTokens[0]
    expected = Object.assign({}, sample, {tsUpdated: pushToken.tsUpdated})
    assert.deepEqual(pushToken, expected)

  it "removes tokens by user id", -> Q.genrun ->
    yield db.createOrUpdate(sample)
    yield db.deleteByUserId(sample.user.id)
    pushTokens = yield db.findByUserId(sample.user.id)
    assert.equal(pushTokens.length, 0, 'There should be 0 pushTokens after deletion')
    assert(yield db.createOrUpdate(sample), null, 'Removed token should not be found')

  it "removes one token by id", -> Q.genrun ->
    yield db.createOrUpdate(sample)
    yield db.deleteById(sample.token.value)
    assert(yield db.createOrUpdate(sample), null, 'Removed token should not be found')
