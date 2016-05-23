
require 'minitest/autorun.rb'
require 'bourne'
require 'mocha/mini_test'

require 'alces/packager/cli'

require 'tempfile'

class TestRepository < MiniTest::Test
  describe 'last_update' do
    def setup
      @repo = Alces::Packager::Repository.new('/path/to/repo')
      @last_update_file = Tempfile.new('last_update')
    end

    def test_last_update_returns_datetime_from_file
      mock_last_update_file
      @last_update_file.write(DateTime.new(2016, 5, 19).to_s)
      @last_update_file.flush

      assert_equal DateTime.new(2016, 5, 19), @repo.last_update
    end

    def test_last_update_saves_the_value_to_the_file
      mock_last_update_file

      @repo.last_update = DateTime.new(2016, 5, 20)

      assert_equal DateTime.new(2016, 5, 20), @repo.last_update
    end

    def test_last_update_file_returns_correct_file
      Alces::Packager::Config.stubs(:last_update_filename).returns('.last_update')
      assert_equal @repo.send(:last_update_file), '/path/to/repo/.last_update'
    end

    def teardown
      @last_update_file.close
      @last_update_file.unlink
    end

    private

    def mock_last_update_file
      @repo.stubs(:last_update_file).returns(@last_update_file.path)
    end
  end

  describe 'requiring_update' do
    def test_returns_repos_requiring_update
      Alces::Packager::Config.stubs(:update_period).returns(10)
      DateTime.stubs(:now).returns(DateTime.new(2016, 5, 19))

      repository_class = Alces::Packager::Repository

      repos_requiring_update_paths = [
        '/needs/an/update',
        '/also/needs/an/update'
      ]
      repos_requiring_update = repos_requiring_update_paths.map do |path|
        repo = repository_class.new(path)
        repo.stubs(:last_update).returns(DateTime.new(2016, 4, 20))
        repo
      end

      repos_not_requiring_update_paths = [
        '/no/update/needed',
        '/also/no/update/needed'
      ]
      repos_not_requiring_update = repos_not_requiring_update_paths.map do |path|
        repo = repository_class.new(path)
        repo.stubs(:last_update).returns(DateTime.new(2016, 5, 15))
        repo
      end

      repository_class.stubs(:all).returns(
        repos_requiring_update + repos_not_requiring_update
      )

      assert_equal repos_requiring_update, repository_class.requiring_update
    end
  end
end
