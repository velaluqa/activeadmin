Backbone.Model.prototype.oldInit = Backbone.Model.prototype.initialize
Backbone.Model.prototype.initialize = (options) ->
  @isFetching = false
  @oldInit(options)

Backbone.Model.prototype.oldFetch = Backbone.Model.prototype.fetch
Backbone.Model.prototype.fetch = (options) ->
  @isFetching = true
  @trigger('fetching')
  @oldFetch(options)
    .done =>
      @isFetching = false
      @trigger('fetched')
