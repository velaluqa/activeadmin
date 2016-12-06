module HelpHelper
  def help_document(doc_name)
    doc = render file: "app/views/admin/help/#{doc_name}"
    headings = []
    path = {}
    last_level = 0
    head_start = doc.index(/<h(\d)>/)
    while head_start
      level = Regexp.last_match[1].to_i
      head_end = doc.index(/<\/h#{level}>/, head_start)
      title = doc[head_start + "<h#{level}>".length...head_end]
      if level < last_level
        path.delete_if { |key,_| (level..last_level).include?(key) }
        path[level] = title
      else
        path[level] = title
      end

      before = doc[0...head_start]
      after = doc[head_start + "<h#{level}>".length...-1]

      doc = before + "<h#{level} id=\"#{heading_id_for_path(path)}\">" + after

      last_level = level
      head_end = doc.index(/<\/h#{level}>/, head_start)
      head_start = doc.index(/<h(\d)>/, head_end)
    end
    doc
  end

  def describe_liquid_drop(drop_name)
    drop_class = drop_name.constantize
    render partial: 'admin/help/email_templates/liquid_drop_description', locals: { drop_class: drop_class }
  end

  private

  def heading_id_for_path(path)
    path.keys.sort.map do |key|
      path[key]
        .underscore
        .gsub(' ', '_')
        .gsub(/&(\w+);/, '\1')
    end.join('-')
  end
end
