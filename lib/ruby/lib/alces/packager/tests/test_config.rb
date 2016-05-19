
# Set up ruby environment - duplicated from libexec/actions/gridware
####
ENV['cw_ROOT'] = '/opt/clusterware'

v = `source #{ENV['cw_ROOT']}/etc/gridware.rc 2> /dev/null && echo ${cw_GRIDWARE_root}`.chomp
ENV['cw_GRIDWARE_root'] = v unless v.empty?

ENV['ALCES_CONFIG_PATH'] ||= "#{ENV['cw_GRIDWARE_root']}/etc:#{ENV['cw_ROOT']}/etc"
ENV['BUNDLE_GEMFILE'] ||= "#{ENV['cw_ROOT']}/lib/ruby/Gemfile"
$: << "#{ENV['cw_ROOT']}/lib/ruby/lib"

require 'rubygems'
require 'bundler'
Bundler.setup(:default)

require 'alces/packager/cli'
####

require 'minitest/autorun'
require 'mocha/mini_test'

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
