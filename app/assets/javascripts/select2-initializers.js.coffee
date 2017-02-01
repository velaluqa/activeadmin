$ ->
  $('.initialize-select2').select2()

  $('.select2-record-search').each (i, el) ->
    $el = $(el)
    $el.select2
      placeholder: $el.data('placeholder')
      allowClear: $el.data('allow-clear') or false
      ajax:
        url: $el.data('url') or '/v1/search.json'
        data: (params) ->
          query =
            query: params.term
          query.models = $el.data('models') if $el.data('models')?
          query
        processResults: (data, params) ->
          groups = ['Study', 'Center', 'Patient', 'Visit', 'ImageSeries', 'Image', 'BackgroundJob']
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

  $('body').on 'select2:open', (e) ->
    if $(e.target).parents('#sidebar').length
      $('.select2-container').addClass('select2--small')
