module UnitTestsUtils::Git
  def self.last_commit_hash(shortened_hash: true)
    git_log_format = shortened_hash ? 'h' : 'H'

    `git log -1 --format="%#{git_log_format}"`.chomp
  end
end
