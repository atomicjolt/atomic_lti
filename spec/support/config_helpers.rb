def with_config(**kwargs)
  old_configs = kwargs.keys.index_with { |key| AtomicLti.send(key) }
  set_configs(kwargs)

  yield
ensure
  set_configs(old_configs)
end

def set_configs(hash)
  hash.each do |key, value|
    set_config(key, value)
  end
end

def set_config(key, value)
  AtomicLti.send("#{key}=", value)
end
