require 'minitest/autorun'
require './scheme'

class SchemeTest < Minitest::Test
  def setup
    @scheme_i = Scheme.new(:iterative)
    @scheme_r = Scheme.new(:recursive)
  end

  def test_math
    assert_equal 2, seval("(+ 1 1)")
    assert_equal 7, seval("(+ 1 (* 2 (/ 6 (* 1 (/ 10 5)))))")
  end

  def test_define
    seval("(define foo 1)")
    assert_equal 1, seval("foo")
  end

  def test_atom
    assert_equal true, seval("(atom? 1)")

    seval("(define hello 1)")
    assert_equal true, seval("(atom? hello)")

    assert_equal true, seval("(atom? (quote hello))")
  end

  def test_quote
    assert_equal :a, seval("(quote a)")
  end

  def test_if
    assert_equal 1, seval("(if true 1 2)")
    assert_equal 2, seval("(if null 1 2)")
    assert_equal 1, seval("(if 4 1 2)")
  end

  def test_eq
    assert_equal true, seval("(eq? 1 1)")
    assert_equal false, seval("(eq? 1 2)")
    assert_equal false, seval("(eq? (quote (1)) 1)")
    assert_equal true, seval("(eq? (quote (:a)) (quote (:a)))")
  end

  def test_car
    assert_equal 1, seval("(car (quote (1)))")
    assert_equal [1], seval("(car (quote ((1) 2)))")
  end

  def test_cdr
    assert_equal [], seval("(cdr (quote (1)))")
    assert_equal [2], seval("(cdr (quote (1 2)))")
  end

  def test_cons
    assert_equal [1], seval("(cons 1 (quote ()))")
    assert_equal [1, 2], seval("(cons 1 (cons 2 (quote ())))")
  end

  def test_begin
    assert_equal 314, seval("(begin (define r 10) (* pi (* r r)))").to_i
  end

  private

  def seval(string)
    i = @scheme_i.parseval(string)
    r = @scheme_r.parseval(string)
    assert_equal r, i
    r
  end

end
