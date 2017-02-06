@Dashboard ?= {}
@Dashboard.Models ?= {}
class Dashboard.Models.Row extends Backbone.Model
  constructor: (attributes) ->
    @widgets = new Dashboard.Collections.Widgets(attributes.widgets)
    delete attributes['widgets']
    super

  toJSON: ->
    return widgets: @widgets.toJSON()
