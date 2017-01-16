@Dashboard ?= {}
@Dashboard.Views ?= {}
class Dashboard.Views.Main extends Backbone.View
  template: JST['dashboard/templates/main']

  initialize: ->
    @subviews ||= {}
    @model.on 'change:editing', @renderEditing
    @listenTo window.dashboard, 'change:editing', @setSortableOptions

  events:
    'click button.edit-dashboard': 'editDashboard'
    'click button.save-dashboard': 'saveDashboard'
    'click button.add-row': 'addRow'
    'sortstart': 'sortstart'

  editDashboard: =>
    @model.set(editing: true)

  saveDashboard: =>
    @model.set(editing: false)

  sortstart: (_, ui) ->
    return unless ui.placeholder.hasClass('sortable-row-placeholder')
    height = ui.item.outerHeight()
    ui.placeholder.css height: "#{height}px"

  addRow: =>
    @model.addEmptyRow()

  renderEditing: =>
    @$el.toggleClass('editing', @model.get('editing'))

  setSortableOptions: (_, editing) =>
    @collectionView.setOptions(sortable: editing)

  render: =>
    @$el.html(@template())
    @collectionView = new Backbone.CollectionView
      el: @$('ul.rows')
      selectable: false
      sortable: window.dashboard.get('editing')
      sortableOptions:
        axis: 'y'
        handle: '.row-sortable-handle'
        forcePlaceholderSize: true
        opacity: 0.6
        placeholder: 'sortable-row-placeholder'
      collection: @model.rows
      modelView: Dashboard.Views.Row
    @collectionView.render()
    @$('ul.rows').disableSelection()
    @renderEditing()
    this
