
require 'minitest/autorun.rb'
require 'bourne'
require 'mocha/mini_test'

require 'alces/packager/cli'
require 'alces/packager/tests/mock_repositories'

class TestHandlerProxy < MiniTest::Test
  describe 'method_missing' do
    ACTIONS_NOT_REQUIRING_UPDATE = [
      :clean,
      :default,
      :depot,
      :export,
      :purge,
      :update
    ]

    include MockRepositories

    def setup
      @handler_args = [[], Commander::Command::Options.new]
      @spied_handler = Alces::Packager::Handler.new(*@handler_args)
      all_actions.map do |action|
        @spied_handler.stubs(action)
      end
      @spied_handler.stubs(:update_repository)
      Alces::Packager::Handler.stubs(:new).returns(@spied_handler)

      @handler_proxy = Alces::Packager::HandlerProxy.new
      @handler_proxy.stubs(:say_repos_requiring_update_message)

      use_mock_repositories
    end

    # TODO: want to test both when no update and that called after update
    def test_does_not_update_for_any_actions_when_not_time
      no_repos_need_updating

      send_all_actions_to_handler

      assert_received(@spied_handler, :update_repository) {|expect| expect.never}
    end

    # TODO: Check update happens before method call
    def test_updates_needed_repositories_when_time
      some_repos_need_updating

      send_all_actions_to_handler

      # Updates repos which have not been updated recently.
      not_recently_updated_repos.map do |repo|
        assert_received(@spied_handler, :update_repository) do |expect|
          expect.with(repo).times(actions_requiring_update.length)
        end
      end

      # Does not update repos which have been updated recently.
      recently_updated_repos.map do |repo|
        assert_received(@spied_handler, :update_repository) do |expect|
          expect.with(repo).never
        end
      end
    end

    private

    def send_all_actions_to_handler
      all_actions.map do |action|
        @handler_proxy.send(action, *@handler_args)
        assert_received(@spied_handler, action)
      end
    end

    def all_actions
      intersection = actions_requiring_update & actions_not_requiring_update
      if intersection != []
        raise "Actions both require and don't require an update: #{intersection}"
      end

      actions_requiring_update + actions_not_requiring_update
    end

    def actions_requiring_update
      Alces::Packager::HandlerProxy::ACTIONS_REQUIRING_UPDATE
    end

    def actions_not_requiring_update
      ACTIONS_NOT_REQUIRING_UPDATE
    end
  end
end

