module DICOM
  class Tag
    class << self
      def keywords
        @keywords ||= load_keywords
      end

      def tags
        @tags ||= load_tags
      end

      def [](tag)
        tags[tag]
      end

      def name(tag)
        tags[tag][:name]
      end

      def by_id(id)
        tag = "#{id[0...4]},#{id[4...9]}"
        tags[tag]
      end

      def keyword(tag)
        tags[tag][:keyword]
      end

      def method_missing(method_name)
        keywords[method_name]
      end

      private

      def load_keywords
        JSON.parse(File.read('vendor/dicom_standard/attributes.json')).map do |attribute|
          [
            attribute['keyword'].to_sym,
            attribute['tag'][1..-2]
          ]
        end.to_h.freeze
      end

      def load_tags
        JSON.parse(File.read('vendor/dicom_standard/attributes.json')).map do |attribute|
          [
            attribute['tag'][1..-2],
            attribute.symbolize_keys.merge(tag: attribute['tag'][1..-2])
          ]
        end.to_h.freeze
      end
    end
  end
end
