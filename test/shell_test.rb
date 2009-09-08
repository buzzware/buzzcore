# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'rubygems'

require 'test/unit'
gem 'Shoulda'; require 'shoulda'

require 'buzzcore/shell_extras'
require 'yore/yore_core'

class ShellTest < Test::Unit::TestCase
  should "raise exception on timeout"
  
  should "not raise exception on non-zero return code, fixed in block. Check result contents"
  
  should "return values from succesfult system call" do
    result = POpen4::shell('ls .')
    assert_instance_of Hash, result
    assert_instance_of String, result[:stdout]
    assert_instance_of String, result[:stderr]
    assert result[:stdout].length > 0
    assert_equal(0, result[:exitcode])
  end

  context "fail correctly" do

    should "raise exception on invalid ls" do
      begin
        result = POpen4::shell('ls asdsadasdasdasdasd')
      rescue ::StandardError => e
        assert_instance_of(POpen4::ExecuteError, e)
        assert_equal 1, e.result[:exitcode]
        assert_instance_of String,e.result[:stdout]
        assert_instance_of String,e.result[:stderr]
        return
      end
      flunk 'should have raised an exception'
    end

    should "not raise exception when fixed in block" do
      result = POpen4::shell('ls asdsadasdasdasdasd') do |r|
        r[:exitcode] = 0
      end
      assert_instance_of Hash, result
      assert_instance_of String, result[:stdout]
      assert_instance_of String, result[:stderr]
      assert_equal(0, result[:exitcode])
    end

  end
end
