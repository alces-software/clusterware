
module MockRepositories
  def use_mock_repositories
    Alces::Packager::Config.stubs(:update_period).returns(10)
    DateTime.stubs(:now).returns(DateTime.new(2016, 5, 19))

    repository_class.stubs(:all).returns(
      repos_requiring_update + repos_not_requiring_update
    )
  end

  def repository_class
    Alces::Packager::Repository
  end

  def repos_requiring_update_paths
    [
      '/needs/an/update',
      '/also/needs/an/update'
    ]
  end

  def repos_requiring_update
    repos_requiring_update_paths.map do |path|
      repo = repository_class.new(path)
      repo.stubs(:last_update).returns(DateTime.new(2016, 4, 20))
      repo
    end
  end

  def repos_not_requiring_update_paths
    [
      '/no/update/needed',
      '/also/no/update/needed'
    ]
  end

  def repos_not_requiring_update
    repos_not_requiring_update_paths.map do |path|
      repo = repository_class.new(path)
      repo.stubs(:last_update).returns(DateTime.new(2016, 5, 15))
      repo
    end
  end
end
