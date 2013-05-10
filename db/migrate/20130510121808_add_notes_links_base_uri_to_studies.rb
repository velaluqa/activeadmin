class AddNotesLinksBaseUriToStudies < ActiveRecord::Migration
  def change
    add_column :studies, :notes_links_base_uri, :string
  end
end
