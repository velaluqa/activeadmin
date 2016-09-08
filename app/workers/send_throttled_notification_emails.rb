# coding: utf-8
class SendThrottledNotificationEmails
  include Sidekiq::Worker

  def perform(throttle)
  end
end
