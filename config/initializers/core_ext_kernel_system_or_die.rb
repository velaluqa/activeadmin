module Kernel
  def system_or_die(command)
    return if system(command)
    fail "Command '#{command}' failed with status #{$?.exitstatus}."
  end
end
