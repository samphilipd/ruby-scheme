require 'minitest/autorun'
require './scheme'

class SchemeTest < Minitest::Test
  def setup
    @scheme = Scheme.new
  end

  def test_eval
    assert_equal 2, @scheme.parseval("(+ 1 1)")
  end

  def test_atom
    assert_equal true, @scheme.parseval("(atom? 1)")

    @scheme.parseval("(define hello 1)")
    assert_equal true, @scheme.parseval("(atom? hello)")

    assert_equal true, @scheme.parseval("(atom? (quote hello))")
  end

  def test_if
    assert_equal 1, @scheme.parseval("(if true 1 2)")
    assert_equal 2, @scheme.parseval("(if null 1 2)")
    assert_equal 1, @scheme.parseval("(if 4 1 2)")
  end

end
