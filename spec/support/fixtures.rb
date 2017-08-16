module Fixtures
  def self.file_content(filename)
    file = File.open(file_path(filename), 'rb')

    file.read
  end

  def self.file_path(filename)
    File.join(File.dirname(__dir__), 'fixtures', filename)
  end
end
