
require 'minitest/autorun.rb'
require 'bourne'
require 'mocha/mini_test'
require 'tempfile'

require 'alces/packager/cli'
require 'alces/packager/tests/mock_repositories'

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
    include MockRepositories

    def setup
      use_mock_repositories
    end

    def test_returns_repos_requiring_update
      assert_equal repos_requiring_update, repository_class.requiring_update
    end
  end
end
