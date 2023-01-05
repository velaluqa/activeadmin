module DICOM
  class FileUtils
    class << self
      DJPEG_COMPATIBLE = [
        "1.2.840.10008.1.2.1.99", # DeflatedExplicitVRLittleEndianTransferSyntax
        "1.2.840.10008.1.2.4.50", # JPEGProcess1TransferSyntax
        "1.2.840.10008.1.2.4.51", # JPEGProcess2_4TransferSyntax
        "1.2.840.10008.1.2.4.53", # JPEGProcess6_8TransferSyntax
        "1.2.840.10008.1.2.4.55", # JPEGProcess10_12TransferSyntax
        "1.2.840.10008.1.2.4.57", # JPEGProcess14TransferSyntax
        "1.2.840.10008.1.2.4.70"  # JPEGProcess14SV1TransferSyntax
      ].freeze
      DJP2K_COMPATIBLE = [
        "1.2.840.10008.1.2.4.90", # JPEG2000LosslessOnlyTransferSyntax
        "1.2.840.10008.1.2.4.91"  # JPEG2000TransferSyntax
      ].freeze
      DJPLS_COMPATIBLE = [
        "1.2.840.10008.1.2.4.80", # JPEGLSLosslessTransferSyntax
        "1.2.840.10008.1.2.4.81"  # JPEGLSLossyTransferSyntax
      ].freeze
      DRLE_COMPATIBLE = [
        "1.2.840.10008.1.2.5" # RLELosslessTransferSyntax
      ].freeze

      def little_endian?(path)
        system("dcmdump #{path.inspect} | grep \"(0002,0010)\" | grep -q \"=LittleEndianExplicit\"")
      end

      def big_endian?(path)
        system("dcmdump #{path.inspect} | grep \"(0002,0010)\" | grep -q \"=BigEndianExplicit\"")
      end

      def transfer_syntax(path)
        res = `dcmdump -Un #{path.inspect} | grep "(0002,0010)"`
        match = res.match(/\[([\d.]+)\]/)
        fail StandardError, "cannot read transfer syntax of file #{path.inspect}" unless match
        match[1]
      end

      def dcmdjpeg(source, target)
        run("dcmdjpeg", "+te", "-v", source, target, "decompress file")
      end

      def dcmdrle(source, target)
        run("dcmdrle", "+te", "-v", source, target, "decompress file")
      end

      def dcmdjpls(source, target)
        run("dcmdjpls", "+te", "-v", source, target, "decompress file")
      end

      def decompress(source, target)
        run("gdcmconv", source, target, "decompress file")
      end

      def dcmcjpeg(source, target, args = "")
        run("dcmcjpeg", "-v", *args, source, targett)
      end

      def ensure_little_endian(source, target)
        case transfer_syntax(source)
        when '1.2.840.10008.1.2.1'
          ::FileUtils.cp(source, target)
        when *DRLE_COMPATIBLE
          dcmdrle(source, target)
        when *DJPEG_COMPATIBLE
          dcmdjpeg(source, target)
        when *DJPLS_COMPATIBLE
          dcmdjpls(source, target)
        when *DJP2K_COMPATIBLE
          decompress(source, target)
        else
          conv_little_endian(source, target)
        end
      end

      def conv_little_endian(source, target)
        system("dcmconv +te #{source.inspect} #{target.inspect}")
      end

      def run(cmd, *args)
        *flags, source, target, action = args

        command = "#{cmd} #{flags.join(" ")} #{source.inspect} #{target.inspect}"
        # TODO: Use proper rails logger to log output of convert commands.
        success = system(command)
        fail StandardError, "could not #{action}" unless success
      end

      def test?(path)
        mimetype = File.open(path) { |f| Marcel::Magic.by_magic(f).type }

        mimetype == "application/dicom"
      end
    end
  end
end
