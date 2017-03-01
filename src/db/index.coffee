Q = require 'q'
genrun = require 'q-genrun'
assert = require 'assert'

esclient = require './esclient'
merge = require '../utils/merge'

module.exports.index = index = "push_tokens"
module.exports.type = type = "push_token"

client = esclient.getClient()
types = ['apn', 'gcm']


validate = (body) ->
  # check that mandatory stuff is there
  assert(body.token.type in types, 'Unknown token type (valid types are apn|gcm)')
  assert(body.token.value, 'Missing token value')
  assert(body.user.id, 'No userid specificed')
  return true


module.exports.createOrUpdate = createOrUpdate = (body, exclusive=false) -> genrun ->
  validate(body)
  yield deleteByUserId(body.user.id) if exclusive
  body = Object.assign({}, body, tsUpdated: Date.now())
  id = body.token.value
  yield client.index({index, type, body, id, refresh: true})


module.exports.deleteById = deleteById = (id) -> genrun ->
  try
    yield client.delete({index, type, id, refresh: true })
  catch e
    throw e if e.status isnt 404
    return { result: 'not found'}
  { result: 'ok' }


module.exports.getById = getById = (value) -> genrun ->
  try
    return (yield client.get({index, type, id: value}))._source
  catch e
    return null if e.status is 404
    throw e


module.exports.findByUsername = findByUsername = (userId) -> genrun ->
  body =
    size: 10000
    query: bool: filter:
      terms:
        "user.username": [].concat(userId)
  esquery = yield client.search({index, type, body})
  return [] if esquery.hits.total is 0
  values = (hit._source for hit in esquery.hits.hits)
  values


module.exports.findByUserId = findByUserId = (userId) -> genrun ->
  body =
    size: 10000
    query: bool: filter:
      terms:
        "user.id": [].concat(userId)
  esquery = yield client.search({index, type, body})
  return [] if esquery.hits.total is 0
  values = (hit._source for hit in esquery.hits.hits)
  values


module.exports.findByUserIds = findByUserId


module.exports.deleteByUserId = deleteByUserId = (userId) -> genrun ->
  pushTokens = yield findByUserId(userId)
  try
    yield deleteById(t.token.value) for t in pushTokens
  catch e
    throw e if e.status isnt 404
