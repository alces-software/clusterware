
require 'minitest/autorun.rb'

require 'alces/packager/cli'
require 'alces/packager/depot_handler'

class TestDepotHandler < MiniTest::Test
  describe 'is_method_shortcut' do
    def setup
      @depot_handler_class = Alces::Packager::DepotHandler
    end

    def test_matches_prefixes
      assert @depot_handler_class.is_method_shortcut('in', :install)
      assert @depot_handler_class.is_method_shortcut('ena', :enable)
    end

    def test_does_not_match_non_prefixes
      refute @depot_handler_class.is_method_shortcut('nst', :install)
      refute @depot_handler_class.is_method_shortcut('nab', :enable)
    end

    def test_ls_is_list_shortcut
      assert @depot_handler_class.is_method_shortcut('ls', :list)
    end

    def test_does_not_error_when_operation_contains_regex_chars
      # Everything fine if these don't error.
      @depot_handler_class.is_method_shortcut('list[', :anything)
      @depot_handler_class.is_method_shortcut('enable]', :does_not_matter)
    end
  end
end
