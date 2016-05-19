
require 'minitest/autorun.rb'
require 'bourne'
require 'mocha/mini_test'

require 'alces/packager/cli'

class TestHandlerProxy < MiniTest::Test
  describe 'method_missing' do
    def test_calls_handler_method
      handler_args = [[], Commander::Command::Options.new]
      spied_handler = Alces::Packager::Handler.new(*handler_args)
      spied_handler.stubs(:install)
      Alces::Packager::Handler.stubs(:new).returns(spied_handler)

      handler_proxy = Alces::Packager::HandlerProxy.new
      handler_proxy.install(*handler_args)

      assert_received(Alces::Packager::Handler, :new)
      assert_received(spied_handler, :install)
    end
  end

  describe 'last_update_time' do
    def setup
      stub_last_update_file = StringIO.new(Time.new(2016, 5, 19).to_s)
      Alces::Packager::Config.stubs(:last_update_file).returns(stub_last_update_file)
    end

    def test_returns_correct_value
      assert_equal Time.new(2016, 5, 19), Alces::Packager::HandlerProxy.new.send(:last_update_time)
    end
  end
end

