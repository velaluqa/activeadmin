window.initializeSimpleSelects = ($elements = $('.initialize-select2')) ->
  $elements.each (i, el) ->
    $el = $(el)
    reloadGetParam = $el.data("reload-get-param")

    $select2 = $el.select2
      placeholder: $el.data('placeholder')
      allowClear: $el.data('allow-clear') or false
      minimumResultsForSearch: if $el.data('hide-search') then Infinity else 5
    if reloadGetParam?
      $select2.on 'change', (e) ->
        url = new URL(window.location)
        searchParams = url.searchParams
        searchParams.set(reloadGetParam, e.target.value)
        url.search = searchParams.toString()
        window.location = url.toString()

window.initializeRecordSearch = ($elements = $('.select2-record-search')) ->
  $elements.each (i, el) ->
    $el = $(el)
    $el.select2
      placeholder: $el.data('placeholder')
      allowClear: $el.data('allow-clear') or false
      templateSelection: (data, container) ->
        if $el.data('template-prepend-type') and data.result_type?
          "#{data.result_type}: #{data.text}"
        else
          data.text
      templateResult: if window.selectedStudyId? or window.accessibleStudyCount is 1
        (state) -> $('<span>' + state.text + '</span>')
      else
        (state) ->
          return $('<span>' + state.text + '</span>') unless state.study_name?
          $('<span>' + state.text + ' <span class="select2-study-note">(' +  state.study_name +  ')</span></span>')
      ajax:
        url: $el.data('url') or '/v1/search.json'
        data: (params) ->
          query =
            query: params.term
            all_studies: $el.data('all-studies') || false
          query.models = $el.data('models') if $el.data('models')?
          query
        processResults: (data, params) ->
          groups = ['Study', 'Center', 'Patient', 'Visit', 'RequiredSeries', 'ImageSeries', 'Image', 'BackgroundJob', 'Role', 'User', 'Comment', 'FormAnswer']
          console.log(groups, data)
          grouped = _
            .chain(data)
            .map (obj) ->
              obj.id = "#{obj.result_type}_#{obj.result_id}"
              obj
            .groupBy (obj) -> obj.result_type
            .value()

          results = []
          results = results.concat(
            for group in groups when grouped[group]?
              { text: group, children: grouped[group] }
          )
          return { results: results }
    $el.on 'change', ->
      $el.val($el.data('clear-value')).trigger('change') if $el.val() == ''

$ ->
  $(document).on 'has_many_add:after', (event, $fieldset) ->
    initializeSimpleSelects($fieldset.find('.initialize-select2'))
    initializeRecordSearch($fieldset.find('.select2-record-search'))

  initializeSimpleSelects($("select:not(.select2-record-search, .no-auto-select2, .choices__input)"))
  initializeRecordSearch()

  $('body').on 'select2:open', (e) ->
    if $(e.target).parents('#sidebar').length
      $('.select2-container').addClass('select2--small')
