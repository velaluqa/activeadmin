@Dashboard ?= {}
@Dashboard.Views ?= {}
class Dashboard.Views.Main extends Backbone.View
  template: JST['dashboard/templates/main']

  initialize: ->
    @subviews ||= {}
    @model.on 'change:editing', @renderEditing
    @listenTo window.dashboard, 'change:editing', @setSortableOptions
    @listenTo window.dashboard, 'change:editWidget', @renderWidgetForm

  events:
    'click .action_item.edit_dashboard': 'editDashboard'
    'click .action_item.save_dashboard': 'saveDashboard'
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

  renderWidgetForm: (model, widget) =>
    if widget?
      tempWidget = new Dashboard.Models.Widget(widget.attributes)
      tempWidget.collection = widget.collection
      @widget_form_view = new Dashboard.Views.WidgetForm
        model: tempWidget
        el: $('#widget-form-modal')
      @widget_form_view.render()
      $('#widget-form-modal').modal('show')
    else
      $('#widget-form-modal').modal('hide')
      @widget_form_view.undelegateEvents()
      @widget_form_view.stopListening()

  render: =>
    @$('#dashboard-container').html(@template())
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
