module V1
  class ApiController < ApplicationController
    rescue_from CanCan::AccessDenied do
      access_denied
    end
  end
end
