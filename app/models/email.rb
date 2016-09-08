class Email
  extend ActiveModel::Naming

  THROTTLING_DELAYS = {
    'none'       => 0,
    'hourly'     => 60*60,
    'daily'      => 24*60*60,
    'weekly'     => 7*24*60*60,
    'monthly'    => 30*24*60*60,
    'quarterly'  => 3*30*24*60*60,
    'semesterly' => 6*30*24*60*60,
    'yearly'     => 12*30*24*60*60
  }.with_indifferent_access

  def self.ensure_throttling_delay(recur)
    return recur if recur.is_a?(Numeric)
    throttling_delay(recur)
  end

  def self.throttling_delay(throttling)
    THROTTLING_DELAYS[throttling]
  end

  def self.throttling_recur(delay)
    THROTTLING_DELAYS.key(delay)
  end
end
