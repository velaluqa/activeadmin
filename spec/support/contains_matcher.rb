RSpec::Matchers.define :contain do |obj, expected|
  def count(array, obj)
    array.inject(0) do |acc, elem|
      acc + (elem == obj ? 1 : 0)
    end
  end

  match do |actual_array|
    count(actual_array, obj) == (expected[:count] || 1)
  end

  failure_message do |actual_array|
    count = count(actual_array, obj)
    "expected\n\n#{actual_array.inspect}\n\nto contain \n\n #{obj.inspect} \n\n to the count of #{expected[:count] || 1} but was found #{count}"
  end
end
