@Dashboard ?= {}
@Dashboard.Models ?= {}
class Dashboard.Models.Report extends Backbone.Model
  url: ->
    '/v1/report.json'

  constructor: (options) ->
    @widget = options.widget
    delete options.widget
    super

  load: ->
    @fetch
      data:
        type: @type()
        params: @params()

  title: ->
    @get('title') or @type()

  type: ->
    @widget.get('type')

  params: ->
    @widget.get('params')
