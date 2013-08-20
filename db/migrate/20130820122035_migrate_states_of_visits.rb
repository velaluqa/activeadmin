class MigrateStatesOfVisits < ActiveRecord::Migration
  def up
    Visit.find_each do |visit|
      case visit.read_attribute(:state)
      when 0
        visit.state = :incomplete_na
        visit.mqc_state = :pending
      when 1
        visit.state = :complete_tqc_passed
        visit.mqc_state = :pending
      when 2
        visit.state = :complete_tqc_passed
        visit.mqc_state = :issues
      when 3
        visit.state = :complete_tqc_passed
        visit.mqc_state = :passed
      end

      visit.save
    end
  end

  def down
    Visit.find_each do |visit|
      if(visit.mqc_state == :passed)
        visit.write_attribute(:state, 3)
      elsif(visit.mqc_state == :issues)
        visit.write_attribute(:state, 2)
      elsif(visit.state == :complete_tqc_passed)
        visit.write_attribute(:state, 1)
      else
        visit.write_attribute(:state, 0)
      end

      visit.save
    end
  end
end
