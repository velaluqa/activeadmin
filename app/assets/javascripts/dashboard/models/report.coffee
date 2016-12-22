@Dashboard ?= {}
@Dashboard.Models ?= {}
class Dashboard.Models.Report extends Backbone.Model
  url: ->
    '/v1/report.json'

  constructor: (attributes) ->
    @type = attributes.type
    @params = attributes.params
    delete attributes.type
    delete attributes.params
    super

  load: ->
    @fetch
      data:
        type: @type
        params: @params
