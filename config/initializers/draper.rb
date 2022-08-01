module Draper
  class CollectionDecorator
    delegate :to_xml, to: :object
  end
end
