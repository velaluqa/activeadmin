class Hash
  def pick(*args)
    args = args.first if args.first.is_a?(Array)
    select { |key, _| args.include?(key) }
  end

  def pick!(*args)
    args = args.first if args.first.is_a?(Array)
    select! { |key, _| args.include?(key) }
  end
end
