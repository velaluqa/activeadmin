class Hash
  def pick(*args)
    select { |key, _| args.include(key) }
  end

  def pick!(*args)
    select! { |key, _| args.include(key) }
  end
end
