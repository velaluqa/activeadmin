@Dashboard ?= {}
@Dashboard.Views ?= {}
class Dashboard.Views.Main extends Backbone.View
  initialize: ->
    @subviews ||= {}

  render: =>
    @$el.html('')
    @model.rows.each (row, i) =>
      @subviews[i] = view = new Dashboard.Views.Row
        model: row
      @$el.append(view.render().el)
    this
