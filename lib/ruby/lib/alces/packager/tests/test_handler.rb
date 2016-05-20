
require 'minitest/autorun.rb'
require 'bourne'
require 'mocha/mini_test'

require 'alces/packager/cli'

class TestHandlerProxy < MiniTest::Test
  describe 'method_missing' do
    def setup
      @handler_args = [[], Commander::Command::Options.new]
      @spied_handler = Alces::Packager::Handler.new(*@handler_args)
      @spied_handler.stubs(:install)
      Alces::Packager::Handler.stubs(:new).returns(@spied_handler)

      Alces::Packager::Config.stubs(:update_period).returns(10)
    end

    # TODO: want to test both when no update and that called after update
    def test_calls_handler_method
      handler_proxy = Alces::Packager::HandlerProxy.new
      handler_proxy.stubs(:last_update_datetime).returns(DateTime.now())
      handler_proxy.install(*@handler_args)

      assert_received(Alces::Packager::Handler, :new)
      assert_received(@spied_handler, :install)
    end

    # TODO: Check update happens before method call
    def test_updates_all_repos_when_time_for_update
      handler_proxy = Alces::Packager::HandlerProxy.new
      handler_proxy.stubs(:last_update_datetime).returns(DateTime.new(2016, 5, 1))
      DateTime.stubs(:now).returns(DateTime.new(2016, 5, 19))
      @spied_handler.stubs(:update_all)

      handler_proxy.install(*@handler_args)

      assert_received @spied_handler, :update_all
      assert_received @spied_handler, :install
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

