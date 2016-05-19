
require 'minitest/autorun'
require 'mocha/mini_test'

require 'alces/packager/cli'
require 'alces/packager/config'

class TestConfig < MiniTest::Test
  describe 'update_period_in_seconds' do
    def setup
      Alces::Packager::Config.stubs(:update_period).returns(10)
    end

    def test_returns_correct_value
      assert_equal 10 * 24 * 60 * 60, Alces::Packager::Config.update_period_in_seconds
    end
  end
end
