module DICOM
  class FileUtils
    class << self
      def big_endian?(path)
        system("dcmdump #{path.inspect} | grep \"(0002,0010)\" | grep -q \"=BigEndianExplicit\"")
      end

      def copy_little_endian(source, target)
        system("dcmconv +te #{source.inspect} #{target.inspect}")
      end

      def test?(path)
        mimetype = File.open(path) { |f| Marcel::Magic.by_magic(f).type }

        mimetype == "application/dicom"
      end
    end
  end
end
