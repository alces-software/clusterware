
require 'minitest/autorun.rb'
require 'bourne'
require 'mocha/mini_test'
require 'tempfile'

require 'alces/packager/cli'
require 'alces/packager/tests/mock_repositories'

class TestRepository < MiniTest::Test
  describe 'update!' do
    def setup
      @repo = Alces::Packager::Repository.new('/path/to/repo')
      @repo.stubs(:metadata).returns({source: 'repo/source'})
      @repo.stubs(:last_update=)

      DateTime.stubs(:now).returns(DateTime.new(2016, 5, 20))
    end

    def test_sets_last_update_when_newly_tracking_master
      stub_sync_response_as('Branch master set up')
      assert_sets_last_update
    end

    # TODO always want to set when updating, even if out-of-sync?
    def test_sets_last_update_when_updating
      stub_sync_response_as('Updating ..')
      assert_sets_last_update
    end

    def test_sets_last_update_when_up_to_date
      stub_sync_response_as('Already up-to-date.')
      assert_sets_last_update
    end

    def test_doesnt_sets_last_update_when_unrecognized_response
      stub_sync_response_as('Something unhandled')
      assert_does_not_set_last_update
    end

    # This case occurs for repos with no source set up, such as the local repo,
    # so we set the last update time to avoid trying to update these with every
    # command.
    def test_sets_last_update_no_source_defined
      # Metadata doesn't have `source` key so cannot sync.
      @repo.stubs(:metadata).returns({})

      assert_sets_last_update
    end

    private

    def stub_sync_response_as(response)
      Alces::Git.stubs(:sync).returns(response)
    end

    def assert_sets_last_update
      @repo.update!
      assert_received(@repo, :last_update=) {|expect| expect.with(DateTime.now).once}
    end

    def assert_does_not_set_last_update
      assert_raises do
        @repo.update!
      end

      assert_received(@repo, :last_update=) {|expect| expect.never}
    end
  end

  describe 'last_update' do
    def setup
      @repo = Alces::Packager::Repository.new('/path/to/repo')
      @last_update_file = Tempfile.new('last_update')
    end

    def test_last_update_returns_lowest_possible_datetime_if_no_file
      mock_last_update_filename # Won't exist.

      assert_equal DateTime.new, @repo.last_update
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
      mock_last_update_filename
      assert_equal @repo.send(:last_update_file), '/path/to/repo/.last_update'
    end

    def teardown
      @last_update_file.close
      @last_update_file.unlink
    end

    private

    def mock_last_update_filename
      Alces::Packager::Config.stubs(:last_update_filename).returns('.last_update')
    end

    def mock_last_update_file
      @repo.stubs(:last_update_file).returns(@last_update_file.path)
    end
  end

  describe 'requiring_update' do
    include MockRepositories

    def setup
      use_mock_repositories
      some_repos_need_updating
    end

    def test_returns_repos_requiring_update
      assert_equal not_recently_updated_repos, repository_class.requiring_update
    end
  end
end
