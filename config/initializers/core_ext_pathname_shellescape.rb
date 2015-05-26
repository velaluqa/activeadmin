class Pathname
  def shellescape
    Shellwords.escape(to_s)
  end
end
