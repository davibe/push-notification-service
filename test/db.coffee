assert = require 'assert'
Q = require 'q'
genrun = require 'q-genrun'

esclient = require '../src/db/esclient'
db = require '../src/db'

sample =
  user:
    id: 'sample_id'
    username: 'sample_username'
  token:
    type: 'apn'
    value: 'SAMPLE_TOKEN'

# export tests so we can re-use them in service test

module.exports.test = test = (db) ->

  afterEach -> genrun ->
    try
      yield db.deleteById(sample.token.value)
    catch e

  it "saves one push token with no errors", -> genrun ->
    yield db.createOrUpdate(sample)

  it "gets the push token", -> genrun ->
    yield db.createOrUpdate(sample)
    pushToken = yield db.getById(sample.token.value)
    expected = Object.assign({}, sample, {tsUpdated: pushToken.tsUpdated})
    assert.deepEqual(pushToken, expected)

  it "find token by user id", -> genrun ->
    yield db.createOrUpdate(sample)
    pushTokens = yield db.findByUserId(sample.user.id)
    pushToken = pushTokens[0]
    expected = Object.assign({}, sample, {tsUpdated: pushToken.tsUpdated})
    assert.deepEqual(pushToken, expected)

  it "does not find token by wrong user id", -> genrun ->
    yield db.createOrUpdate(sample)
    pushTokens = yield db.findByUserId(sample.user.id + "wrong")
    assert.equal(pushTokens.length, 0, 'Should not find any')

  it "find token by user ids", -> genrun ->
    yield db.createOrUpdate(sample)
    pushTokens = yield db.findByUserId([sample.user.id])
    pushToken = pushTokens[0]
    expected = Object.assign({}, sample, {tsUpdated: pushToken.tsUpdated})
    assert.deepEqual(pushToken, expected)

  it "removes tokens by user id", -> genrun ->
    yield db.createOrUpdate(sample)
    yield db.deleteByUserId(sample.user.id)
    pushTokens = yield db.findByUserId(sample.user.id)
    assert.equal(pushTokens.length, 0, 'There should be 0 pushTokens after deletion')
    assert(yield db.createOrUpdate(sample), null, 'Removed token should not be found')

  it "removes one token by id", -> genrun ->
    yield db.createOrUpdate(sample)
    yield db.deleteById(sample.token.value)
    assert(yield db.createOrUpdate(sample), null, 'Removed token should not be found')


describe 'db should work allright', ->

  before ->
    this.timeout(60 * 1000 * 2)
    genrun ->
      yield esclient.waitES()
      yield esclient.indexTemplatesInit()

  test(db)
