module.exports =
  order: 0 # template priority order
  template: 'push_tokens*'
  aliases: # possible aliases of this index
    push_tokens: {}
  mappings: # Mappings to apply to the matching index
    push_token:
      dynamic: 'false'
      properties:
        user:
          type: 'object'
          properties:
            id:
              type: 'string'
              index: 'not_analyzed'
            username:
              type: 'string'
              index: 'not_analyzed'
        token:
          type: 'object'
          properties:
            type:
              type: 'string'
              index: 'not_analyzed'
            value:
              type: 'string'
              index: 'not_analyzed'
        tsCreated: type: 'date', format: 'strict_date_optional_time||epoch_millis'
        tsUpdated: type: 'date', format: 'strict_date_optional_time||epoch_millis'

  settings: {} # settings to apply to matching index
