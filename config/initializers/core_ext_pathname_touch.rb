class Pathname
  def touch
    FileUtils.touch(self)
  end
end
