require 'minitest/autorun'
require './scheme'

class SchemeTest < Minitest::Test
  def setup
    @scheme = Scheme.new
  end

  def test_eval
    assert_equal @scheme.parseval("(+ 1 1)"), 2
  end

  def test_atom
    assert_equal @scheme.parseval("(atom? 1)"), true

    @scheme.parseval("(define hello 1")
    assert_equal @scheme.parseval("(atom? hello)"), true

    assert_equal @scheme.parseval("(atom? (quote hello))"), true
    assert_equal @scheme.parseval("(atom? (not an atom))"), false
  end

end
