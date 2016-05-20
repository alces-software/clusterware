
require 'minitest/autorun.rb'
require 'bourne'
require 'mocha/mini_test'

require 'alces/packager/cli'

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

    def setup
      @handler_args = [[], Commander::Command::Options.new]
      @spied_handler = Alces::Packager::Handler.new(*@handler_args)
      all_actions.map do |action|
        @spied_handler.stubs(action)
      end
      Alces::Packager::Handler.stubs(:new).returns(@spied_handler)

      Alces::Packager::Config.stubs(:update_period).returns(10)

      @handler_proxy = Alces::Packager::HandlerProxy.new
    end

    # TODO: want to test both when no update and that called after update
    def test_does_not_update_for_any_actions_when_not_time
      update_is_not_due

      send_all_actions_to_handler

      assert_received(@spied_handler, :update_all) {|expect| expect.never}
    end

    # TODO: Check update happens before method call
    def test_updates_for_required_actions_when_time
      update_is_due
      @spied_handler.stubs(:update_all)

      send_all_actions_to_handler

      assert_received(@spied_handler, :update_all) {|expect| expect.times(actions_requiring_update.length)}
    end

    def update_is_due
      @handler_proxy.stubs(:last_update_datetime).returns(DateTime.new(2016, 5, 1))
      DateTime.stubs(:now).returns(DateTime.new(2016, 5, 19))
    end

    def update_is_not_due
      @handler_proxy.stubs(:last_update_datetime).returns(DateTime.now())
    end

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

  describe 'last_update_datetime' do
    def setup
      stub_last_update_file = StringIO.new(DateTime.new(2016, 5, 19).to_s)
      Alces::Packager::Config.stubs(:last_update_file).returns(stub_last_update_file)
    end

    def test_returns_correct_value
      assert_equal DateTime.new(2016, 5, 19), Alces::Packager::HandlerProxy.new.send(:last_update_datetime)
    end
  end
end

