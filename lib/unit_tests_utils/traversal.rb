class UnitTestsUtils::Manifest::Traversal
  attr_reader :manifest

  def initialize(yml_manifest)
    @manifest = yml_manifest
  end

  def find(path)
    traverse(manifest, path)
  end

  protected

  def traverse(manifest, path)
    raw_first, *rest = path.split('/').reject { |e| e.to_s.empty? }
    first = formatted_key(raw_first)
    rest = rest.join('/')

    if rest == ""
      if first.include?('=')
        components = first.split('=')
        found = manifest.find { |pair| pair[components.first] == components.last }
        return found
      end
      return manifest[first]
    end

    if first.include?('=')
      components = first.split('=')
      found = manifest.find { |pair| pair[components.first] == components.last }
      return traverse(found, rest)
    end

    if manifest.is_a?(Hash)
      if manifest.key?(first)
        return traverse(manifest[first], rest)
      end
    end

    raise NotImplementedError if !is_optional(first)
  end

  private

  def is_optional(key)
    key.end_with?('?')
  end

  def formatted_key(key)
    return key.chop if is_optional(key)

    key
  end
end
