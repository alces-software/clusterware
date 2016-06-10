
module MockRepositories
  def use_mock_repositories
    Alces::Packager::Config.stubs(:update_period).returns(10)
    DateTime.stubs(:now).returns(DateTime.new(2016, 5, 19))

    repository_class.stubs(:all).returns(
      not_recently_updated_repos + recently_updated_repos
    )
  end

  def some_repos_need_updating
    stub_update_period(10)
  end

  def no_repos_need_updating
    stub_update_period(50)
  end

  def repository_class
    Alces::Packager::Repository
  end

  def not_recently_updated_repos
    not_recently_updated_repo_paths.map do |path|
      repo = repository_class.new(path)
      repo.stubs(:last_update).returns(DateTime.new(2016, 4, 20))
      repo
    end
  end

  def recently_updated_repos
    recently_updated_repo_paths.map do |path|
      repo = repository_class.new(path)
      repo.stubs(:last_update).returns(DateTime.new(2016, 5, 15))
      repo
    end
  end

  private

  def not_recently_updated_repo_paths
    [
      '/needs/an/update',
      '/also/needs/an/update'
    ]
  end

  def recently_updated_repo_paths
    [
      '/no/update/needed',
      '/also/no/update/needed'
    ]
  end

  def stub_update_period(value)
    Alces::Packager::Config.stubs(:update_period).returns(value)
  end
end
