module HelpHelper
  def help_document(doc_name)
    doc = render file: "app/views/admin/help/#{doc_name}"
    headings = []
    paths = []
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
      paths.push(path.deep_dup)

      before = doc[0...head_start]
      after = doc[head_start + "<h#{level}>".length...-1]

      doc = before + "<h#{level} id=\"#{heading_id_for_path(path)}\">" + after

      last_level = level
      head_end = doc.index(/<\/h#{level}>/, head_start)
      head_start = doc.index(/<h(\d)>/, head_end)
    end
    [doc, paths]
  end

  def extract_help_headings(paths)
    paths.each do |path|
      max_level = path.keys.sort.max
      path[:anchor] = heading_id_for_path(path)
      path[:title] = path[max_level]
    end
    extract_help_groups(2, paths)
  end

  def extract_help_groups(level, paths)
    paths.select { |path| path[level] && path[level+1].nil? }.map do |path|
      grouped = paths.select { |spath| spath[level] == path[:title] && spath[level+1] }
      path[:sub_headings] = extract_help_groups(level+1, grouped)
      path
    end
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
