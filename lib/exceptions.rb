module Exceptions
  class FormNotFoundError < ActiveRecord::RecordNotFound
    attr_reader :form_name, :form_version, :case

    def initialize(name, version, the_case)
      @form_name = name
      @form_version = version
      @case = the_case
    end
  end

  class CaseNotFoundError < ActiveRecord::RecordNotFound
    attr_reader :case_id

    def initialize(case_id)
      @case_id = case_id
    end
  end
end
