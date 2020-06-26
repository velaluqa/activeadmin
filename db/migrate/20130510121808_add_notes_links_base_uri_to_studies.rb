class AddNotesLinksBaseUriToStudies < ActiveRecord::Migration[4.2]
  def change
    add_column :studies, :notes_links_base_uri, :string
  end
end
