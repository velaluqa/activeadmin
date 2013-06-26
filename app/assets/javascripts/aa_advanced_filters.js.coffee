hide_fake_sidebar_entry = ->
  $('#advanced_filter_data_sidebar_section').hide()

replace_stock_filter = (id) ->
  $('#q_'+id).replaceWith('<input id="q_'+id+'" type="hidden" name="q['+id+'_in][]" style="width: 100%"/>')

$(document).ready ->
  return unless filter_select2_id?
  hide_fake_sidebar_entry()
  replace_stock_filter(filter_select2_id)

  $(".clear_filters_btn").off('click')
  $(".clear_filters_btn").on 'click', ->
    window.location.search = '?clear_filter=true'
    false
  
  $('#q_'+filter_select2_id).select2({
    multiple: true
    placeholder: 'Please select filters'
    allowClear: true
    minimumInputLength: 3
    ajax: {
      url: '/images_search/search.json'
      dataType: 'json'
      data: (term, page) ->
        return { term: term }
      results: (data, page) ->
        return { results: data.results }
    }
    formatResult: (item) ->
      type_string = switch item.type
        when 'study' then 'Study'
        when 'center' then 'Center'
        when 'patient' then 'Patient'
        when 'visit' then 'Visit'
        when 'image_series' then 'Image Series'

      return type_string + ': ' + item.text
    initSelection: (element, callback) ->
      callback(selected_filters)           
  })

  $('#q_'+filter_select2_id).select2('val', selected_filters)
