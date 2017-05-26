module Kernel
  def system_or_die(command)
    return if system(command)
    raise "Command '#{command}' failed with status #{$CHILD_STATUS.exitstatus}."
  end
end
