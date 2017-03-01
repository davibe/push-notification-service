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
              type: 'keyword'
              index: true
            username:
              type: 'keyword'
              index: true
        token:
          type: 'object'
          properties:
            type:
              type: 'keyword'
              index: true
            value:
              type: 'keyword'
              index: true
        tsCreated: type: 'date', format: 'strict_date_optional_time||epoch_millis'
        tsUpdated: type: 'date', format: 'strict_date_optional_time||epoch_millis'

  settings: {} # settings to apply to matching index
