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
    data: filter_select2_data
    initSelection: (element, callback) ->
      values = element.val().split(',')
      selection = ({id: value, text: filter_options_map[value]} for value in values when filter_options_map[value]?)

      callback(selection)
    })

  $('#q_'+filter_select2_id).select2('val', selected_filters)
