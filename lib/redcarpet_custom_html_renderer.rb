require 'uv'

class RedcarpetCustomHtmlRenderer < Redcarpet::Render::HTML # :nodoc:
  def block_code(code, lang)
    if lang == 'text'
      "<pre>#{code}</pre>"
    else
      Uv.parse(code, 'xhtml', lang, false, 'active4d')
    end
  end
end
