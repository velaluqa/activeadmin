class ImagesSearch < ActiveRecord::Base

  self.table_name = 'images_search'

  attr_accessible :text, :result_id, :result_type

  def self.perform_search(term)
    ImagesSearch.where('text like ?', ['%'+term+'%']).order('(case when result_type = \'study\' then 0 when result_type = \'center\' then 1 when result_type = \'patient\' then 2 when result_type = \'visit\' then 3 else 23 end), text asc')
  end
end
