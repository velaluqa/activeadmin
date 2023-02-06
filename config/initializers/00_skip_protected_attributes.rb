class ActiveRecord::Base
  # TODO: Go through all attr_accessible definitions and replace them
  # with strong parameter declarations in active admin resources (see #6065).
  def self.attr_accessible(*); end
end
