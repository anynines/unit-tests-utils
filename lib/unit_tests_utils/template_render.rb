require 'erb'

class UnitTestsUtils::TemplateRender
  include ERB::Util

  attr_reader :template_file

  def initialize(template_file)
    @template_file = File.read(template_file)
  end

  def render(vars = {})
    bind = empty_binding

    vars.each { |key, value| bind.local_variable_set(key, value) }

    ERB.new(template_file).result(bind)
  end

  def save(dst_file, vars = {})
    rendered_content = render(vars)

    File.open(dst_file, 'w') { |f| f.write(rendered_content) }
  end

  private

  def empty_binding
    binding
  end
end
