module Exceptions
  class FormNotFoundError < ActiveRecord::RecordNotFound
    attr_reader :form_name, :form_version

    def initialize(name, version)
      @form_name = name
      @form_version = version
    end
  end
end
