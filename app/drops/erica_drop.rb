class EricaDrop < Liquid::Rails::Drop # :nodoc:
  class << self
    attr_accessor :last_description

    def desc(*options)
      desc, type = options
      @last_description = {
        desc: desc,
        type: type
      }
    end

    def attributes_with_desc(*attrs)
      attributes_without_desc(*attrs)
      attrs.each do |attr|
        _set_attr_description(attr)
      end
    end
    alias_method :attributes_without_desc, :attributes
    alias_method :attributes, :attributes_with_desc

    def attribute(attr)
      @_attributes.push(attr)

      return if method_defined?(attr)

      _set_attr_description(attr)
      define_method(attr) do
        object.send(attr) if object.respond_to?(attr, true)
      end
    end

    def associate_with_desc(type, names)
      last_description = @last_description
      @last_description = nil

      associate_without_desc(type, names)

      return if last_description.nil?
      names.each do |name|
        _associations[name][:description] = last_description
        _attr_descriptions.delete(name)
      end
    end
    alias_method :associate_without_desc, :associate
    alias_method :associate, :associate_with_desc

    def method_added(name)
      super
      return unless @last_description
      _attr_descriptions[name] ||= @last_description
      @last_description = nil
    end

    def _attr_descriptions
      @_attr_descriptions ||= {}
    end

    def _set_attr_description(name)
      _attr_descriptions[name] ||= @last_description
      @last_description = nil
    end
  end

  def self.inherited(base)
    super
    base.class_eval do
      desc 'Unique identifier for the resource.', :integer
      attribute(:id)

      desc 'Creation date of the resource.', :datetime
      attribute(:created_at)

      desc 'Last update of the resource.', :datetime
      attribute(:updated_at)

      desc 'The class name of the resource encapsulated by this Drop.', :string
      def class_name
        object.class.to_s
      end
    end
  end
end
