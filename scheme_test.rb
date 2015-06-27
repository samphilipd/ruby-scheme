require 'minitest/autorun'
require './scheme'

class SchemeTest < Minitest::Test
  def setup
    @scheme = Scheme.new
  end

  def test_eval
    assert_equal @scheme.parseval("(+ 1 1)"), 2
  end
end
