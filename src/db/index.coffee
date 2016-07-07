Q = require 'q-extended'
assert = require 'assert'

esclient = require './esclient'
merge = require '../utils/merge'

module.exports._index = _index = "push_tokens"
module.exports._type = _type = "push_token"

client = esclient.getClient({index: _index, type: _type})
types = ['apn', 'gcm']


validate = (body) ->
  # check that mandatory stuff is there
  assert(body.token.type in types, 'Unknown token type (valid types are apn|gcm)')
  assert(body.token.value, 'Missing token value')
  assert(body.user.id, 'No userid specificed')
  return true


module.exports.createOrUpdate = createOrUpdate = (body, exclusive=false) -> Q.genrun ->
  yield deleteByUserId(body.userId) if exclusive
  validate(body)
  body = Object.assign({}, body, tsUpdated: Date.now())
  id = body.token.value
  yield client.index({body, id, refresh: true})


module.exports.deleteById = deleteById = (id) -> Q.genrun ->
  try
    yield client.delete({ id, refresh: true })
  catch e
    throw e if e.status isnt 404


module.exports.getById = getById = (value) -> Q.genrun ->
  try
    return (yield client.get(id: value))._source
  catch e
    return null if e.status is 404
    throw e


module.exports.findByUserId = findByUserId = (userId) -> Q.genrun ->
  body =
    size: 10000
    filter:
      terms:
        "user.id": [].concat(userId)
  esquery = yield client.search({body})
  return [] if esquery.hits.total is 0
  values = (hit._source for hit in esquery.hits.hits)
  values


module.exports.findByUserIds = findByUserId


module.exports.deleteByUserId = deleteByUserId = (userId) -> Q.genrun ->
  pushTokens = yield findByUserId(userId)
  try
    yield deleteById(t.token.value) for t in pushTokens
  catch e
    throw e if e.status isnt 404
