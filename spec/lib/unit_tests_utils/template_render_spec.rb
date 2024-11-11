require 'spec_helper'
require 'yaml'

describe UnitTestsUtils::TemplateRender do
  subject { described_class.new(template) }

  let(:template) { 'spec/fixtures/template-with-vars.yml' }
  let(:output_file) { '/tmp/template-with-vars.yml' }
  let(:vars) do
    {
      first_var_content: 'first_content',
      second_var_content: 'second_content'
    }
  end

  it 'renders the template in an output file' do
    subject.save(output_file, vars)
    manifest = YAML.load_file(output_file)

    expect(manifest['first_level']['first_entry']).to eq(vars[:first_var_content])
    expect(manifest['first_level']['second_entry']).to eq(vars[:second_var_content])
  end
end
