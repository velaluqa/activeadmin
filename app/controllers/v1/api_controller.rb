module V1
  class ApiController < ApplicationController
    rescue_from CanCan::AccessDenied do
      access_denied
    end

    def authorize_one!(actions, subject)
      unless actions.any? { |a| can?(a, subject) }
        raise CanCan::AccessDenied.new(current_user, actions, subject)
      end
    end

    def authorize_combination!(*combinations)
      unless combinations.any? { |a, s| can?(a, s) }
        raise CanCan::AccessDenied.new(current_user, combinations)
      end
    end
  end
end
