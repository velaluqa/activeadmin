module Exceptions
  class FormNotFoundError < ActiveRecord::RecordNotFound
    attr_reader :form_name, :case

    def initialize(name, the_case)
      @form_name = name
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
