class EricaDrop < Liquid::Rails::Drop # :nodoc:
  def class_name
    object.class.to_s
  end
end
