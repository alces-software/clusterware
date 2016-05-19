
require 'minitest/autorun.rb'
require 'mocha/mini_test'

require 'alces/packager/cli'

class TestHandlerProxy < MiniTest::Test
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

