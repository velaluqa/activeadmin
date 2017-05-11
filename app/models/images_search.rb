# ## Schema Information
#
# Table name: `images_search`
#
# ### Columns
#
# Name               | Type               | Attributes
# ------------------ | ------------------ | ---------------------------
# **`result_id`**    | `text`             |
# **`result_type`**  | `text`             |
# **`study_id`**     | `integer`          |
# **`text`**         | `string`           |
#
class ImagesSearch < ActiveRecord::Base
  self.table_name = 'images_search'

  attr_accessible :text, :result_id, :result_type

  def self.perform_search(term, selected_study_id = nil)
    if selected_study_id.nil?
      ImagesSearch.where('text like ?', ['%' + term + '%']).order('(case when result_type = \'study\' then 0 when result_type = \'center\' then 1 when result_type = \'patient\' then 2 when result_type = \'visit\' then 3 else 23 end), text asc')
    else
      ImagesSearch.where('study_id = ? and text like ?', selected_study_id, ['%' + term + '%']).order('(case when result_type = \'study\' then 0 when result_type = \'center\' then 1 when result_type = \'patient\' then 2 when result_type = \'visit\' then 3 else 23 end), text asc')
    end
  end
end
