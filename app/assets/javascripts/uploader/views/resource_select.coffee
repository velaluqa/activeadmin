@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.ResourceSelect extends Backbone.View
  events:
    'change select': 'change'

  state: 'reset'

  initialize: (options = {}) ->
    @selectableAttribute = options.selectableAttribute
    @selectableCollection = options.selectableCollection
    @dependentAttribute = options.dependentAttribute

    @creationUrl = options.creationUrl

    @collection = @model[@selectableCollection]

    @listenTo @model, "change:#{@selectableAttribute}", =>
      console.log 'render because of attribute change', @selectableAttribute
      @render()
    @listenTo @collection, 'request', =>
      @state = 'request'
      @render()
    @listenTo @collection, 'sync', =>
      console.log 'render because of sync', @selectableCollection
      @state = 'sync'
      @render()
    @listenTo @collection, 'reset', =>
      console.log 'render because of reset', @selectableCollection
      @state = 'reset'
      @render()

  change: =>
    value = @$select.val()
    return @create() if value is 'create'
    selectedModel = @collection.get(value)
    return unless selectedModel?
    @model.set(@selectableAttribute, selectedModel)

  data: =>
    options = []
    options.concat @collection.map (resource) ->
      { id: resource.get('id'), text: resource.text() }

  render: =>
    @$select ?= @$('select')

    switch @state
      when 'request'
        @$select.html('').select2
          placeholder: 'Loading ...'
      when 'sync', 'reset'
        if @state is 'reset' and @dependentAttribute?
          @$select.html('').select2
            placeholder: "Please select #{@dependentAttribute} first"
          @$select.prop('disabled', true)
        else
          @$select.html('').select2
            placeholder: "Select #{@selectableAttribute}"
            data: @data()
          @$select.prop('disabled', false)
          @$select
            .val(@model.get(@selectableAttribute)?.get('id') or '')
            .trigger('change.select2')

    this
