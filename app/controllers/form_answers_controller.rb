require 'pp'

class FormAnswersController < ApplicationController
  def create
    # params: answers as json hash, rest from session?
    pp params
  end
end
