elasticsearch = require 'elasticsearch'
URL = require 'url'
Q = require 'q-extended'
requireDir = require 'require-dir'
assert = require 'assert'

merge = require '../utils/merge'


conf = { elasticsearch: process.env.ELASTICSEARCH_URL }

singleton = do ->
  c = null
  ->
    return c if c
    c = new elasticsearch.Client(
      host: conf.elasticsearch
      log: 'info'
      # sniffOnConnectionFault: true
      # sniffInterval: 60 * 1000 # ms
      defer: -> Q.defer()
    )
    # Cliet init options ref:
    # https://www.elastic.co/guide/en/elasticsearch/client/javascript-api/current/configuration.html

console.log "Elastisearch Client will use #{conf.elasticsearch}"


# Returns a configured elasticsearch client.
# configured = it has default parameters you don't have to specify each time
getClient = (defaultParams) ->
  client = singleton()

  # Enriches first parameter (object)
  # to have `defaultParams` default attributes
  P = (params) -> merge({}, defaultParams, params)

  # Returns a function calling original `o[fn]` with
  # first param enriched by `P()`
  Pfn = (o, fn) -> (params, args...) -> o[fn](P(params), args...)

  configuredClient =
    ping: (args) -> client.ping(args) # does not need wrapping
    indices: {}

  for method in "create index get delete search count exists mget bulk scroll update".split(' ')
    configuredClient[method] = Pfn(client, method)

  for method in "exists delete create getMapping refresh putTemplate getTemplate analyze putMapping deleteAlias putAlias".split(' ')
    configuredClient.indices[method] = Pfn(client.indices, method)

  configuredClient


# Returns a promise. Resolves when elasticsearch is available
waitES = -> Q.genrun ->
  # create client that does not log errors
  loglessClient = new elasticsearch.Client(host: conf.elasticsearch, log: [])
  done = false
  while not done
    try
      yield Q.delay 1000
      console.log 'Waiting for ElasticSearch to be available..'
      yield loglessClient.ping()
      console.log conf.elasticsearch
      done = true
    catch e
      console.log 'Retrying..'


# initialize index templates
indexTemplatesInit = (filter=false, silent=false) -> Q.genrun ->
  client = singleton()

  templates = requireDir './templates'

  for templateName, template of templates

    if filter
      if not (templateName in filter) then continue

    console.log "estemplates: updating template '#{templateName}'" if not silent
    yield client.indices.putTemplate
      name: templateName
      create: false # also allow to update
      body: template

    if not yield client.indices.exists(index: template.template)
      index = "#{templateName}_v0"
      console.log "estemplates: creating default index '#{index}'" if not silent
      yield client.indices.create({index})

    # When mappings change it's possible that new mappings are compatible with the old
    # ones. So we could try to apply them to the "current" indexes.
    # The _current_ indexes are the one referred to by the alias.
    # We could probably try to issue 'putMappings' on the alias itself hoping that they
    # get applied to the corresponding indexes
    for aliasName, aliasData of template.aliases
      for type, mappings of template.mappings
        try
          yield client.indices.putMapping
            index: aliasName
            type: type
            body: mappings
          console.log "Updated mappings on #{aliasName}/#{type}"
        catch e
          console.log "WARNING: unable to apply mappings", e, e.stack.split('\n')
          console.log "WARNING: index '#{aliasName}' needs to be reindexes"

  console.log 'estemplates: all templates have been initialized/updated' if not silent


module.exports = {getClient, waitES, indexTemplatesInit}
