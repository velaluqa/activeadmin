class ReadonlyInput < Formtastic::Inputs::StringInput
  def to_html
    input_wrapping do
      label_html <<
      template.content_tag('div', input_html_options[:value] || @object.send(method))
    end
  end
end
