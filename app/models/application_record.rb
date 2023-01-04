class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def versions_item_name
    return name if respond_to?(:name)

    to_s
  end
end
