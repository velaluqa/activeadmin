$(document).ready ->
  images_tree = $('#images_tree')

  images_tree.tree({
    dragAndDrop: true
    autoEscape: false
    data: tree_data
    onCanMoveTo: (moved_node, target_node, position) ->
      if(moved_node.type == 'image' and target_node.type == 'image_series' and position == 'inside')
        return true
      else if(moved_node.type == 'image' and target_node.type == 'image' and (position == 'before' or position == 'after'))
        return true
      else
        return false
  })

  # $('#add_series_btn').click ->
  #   images_tree.tree('appendNode', {label: 'New Series', id: 'image_series__new', type: 'image_series'})

  $('#save_form').submit ->
    $('#assignment').val(images_tree.tree('toJson'))
    return true
    