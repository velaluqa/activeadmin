hide_fake_sidebar_entry = ->
  $('#advanced_filter_data_sidebar_section').hide()

$(document).ready ->
  return unless filter_select2_id?
  hide_fake_sidebar_entry()

  $('.clear_filters_btn').off('click')
  $('.clear_filteRs_btn').on 'click', ->
    window.location.search = '?clear_filter=true'
    false

  $("#q_#{filter_select2_id}").prop('name', "q[#{filter_select2_id}_in][]")
  
  $element = $("#q_#{filter_select2_id}").select2
    multiple: true
    placeholder: 'Please select filters'
    allowClear: true
    minimumInputLength: 3
    ajax: {
      url: '/images_search/search.json'
      dataType: 'json'
      data: (params) ->
        return { term: params.term }
      processResults: (data) ->
        return { results: data.results }
    }
    templateResult: (item) ->
      type_string = switch item.type
        when 'study' then 'Study'
        when 'center' then 'Center'
        when 'patient' then 'Patient'
        when 'visit' then 'Visit'
        when 'image_series' then 'Image Series'

      return type_string + ': ' + item.text

  $element.val([]).trigger('change')
  for filter in selected_filters
    option = new Option(filter.text, filter.id, true, true)
    $element.append(option)

  $element.trigger('change')


$(document).on 'ready page:load', ->
  # Clear Filters button
  $('.clear_filters_btn').unbind('click')
  $('.clear_filters_btn').click ->
    params = window.location.search.slice(1).split('&')
    params.push 'clear_filter=true'
    regex = /^(q\[|q%5B|q%5b|page|commit)/
    window.location.search = (param for param in params when not param.match(regex)).join('&')
