@ImageUploader ?= {}
@ImageUploader.Views ?= {}
class ImageUploader.Views.ResourceSelect extends Backbone.View
  events:
    'change select': 'change'
    'click .select2': 'reload'

  state: 'reset'

  initialize: (options = {}) ->
    @selectableAttribute = options.selectableAttribute
    @selectableCollection = options.selectableCollection
    @dependentAttribute = options.dependentAttribute

    @creatableResource = options.creatableResource
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

  reload: =>
    @collection.fetch(silent: true).then =>
      @$select.select2('open')

  create: =>
    url = @creationUrl
    url = url(@model) if _.isFunction(url)
    window.open(url, "Create New #{@creatableResource}")
    @$select.val('').trigger('change')

  change: =>
    value = @$select.val()
    return @create() if value is 'create'
    selectedModel = @collection.get(value)
    return unless selectedModel?
    @model.set(@selectableAttribute, selectedModel)

  data: =>
    options = []
    if @creatableResource? and currentUser.can('create', @creatableResource)
      options.push(id: 'create', text: "Create New #{@creatableResource}")
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
