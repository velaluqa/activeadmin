module ActiveAdmin
  module Views
    class AttributesTable
      def domino_link_row(resource)
        row 'Domino' do
          url = resource.lotus_notes_url

          if resource.domino_unid.nil? or url.nil?
            nil
          else
            link_to(resource.domino_unid, url)
          end
        end
      end
    end
  end
end
