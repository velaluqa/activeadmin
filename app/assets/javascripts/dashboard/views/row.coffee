@Dashboard ?= {}
@Dashboard.Views ?= {}
class Dashboard.Views.Row extends Backbone.View
  className: 'row'
  template: JST['dashboard/templates/row']

  initialize: ->
    @subviews ||= {}

    @listenTo @model.widgets, 'add remove', @setSizeClass

  setSizeClass: =>
    if @model.widgets.length > 6
      @$el.attr(class: 'row size-6')
    else if @model.widgets.length < 1
      @$el.attr(class: 'row size-1')
    else
      @$el.attr(class: "row size-#{@model.widgets.length}")

  render: =>
    @setSizeClass()
    @$el.html(@template())
    collectionView = new Backbone.CollectionView
      el: @$('ul')
      selectable: false
      sortable: true
      sortableOptions:
        axis: 'xy'
        connectWith: '.row'
      collection: @model.widgets
      modelView: Dashboard.Views.Widget
    collectionView.render()
    @$('ul').disableSelection()
    this
