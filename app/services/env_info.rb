class EnvInfo

  def call
    {
      env_name: env_name,
      ami_id: ami_id,
      git_sha: git_sha
    }
  end

  private

  def env_name
    ENV['ENV_NAME'] || 'Not set'
  end

  def ami_id
    ENV['AMI_ID'] || 'Not set'
  end

  def git_sha
    `git show --pretty=%H -q`&.chomp || 'Not set'
  end
end
