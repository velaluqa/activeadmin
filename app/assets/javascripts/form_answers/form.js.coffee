$ ->
  $("#form_answer_form_definition_id").on "change", (e) ->
    console.log "select", e.target.value
    window.location.search = "?form_definition_id=#{e.target.value}"
