require 'report/overview'

module Report
  def self.mappings
    @mappings ||= {
      Visit => { 'state' => Visit::STATE_SYMS }
    }
  end
end
