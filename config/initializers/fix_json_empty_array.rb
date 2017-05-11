# Rails "bug": https://github.com/rails/rails/pull/8862

module ActionDispatch
  class Request < Rack::Request
    def deep_munge(hash)
      hash.each do |k, v|
        case v
        when Array
          if !v.empty? && v.all?(&:nil?)
            hash[k] = nil
            next
          end
          v.grep(Hash) { |x| deep_munge(x) }
          v.compact!
        when Hash
          deep_munge(v)
        end
      end

      hash
    end
  end
end
