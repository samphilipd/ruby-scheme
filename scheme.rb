require 'pry'
require 'readline'

class Scheme
  class SchemeSyntaxError < StandardError; end
  class NullLambdaError < StandardError; end
  class EmptyListError < StandardError; end

  #### PARSING ####

  # Splits a string of characters into an array of tokens, outputting e.g.
  # => ["(", "begin", "(", "define", "r", "10", ")", "(", "*", "pi", "(", "*", "r", "r", ")", ")", ")"]
  def tokenize(chars)
    chars.gsub('(', ' ( ').gsub(')', ' ) ').split.freeze
  end

  # Reads from a list of tokens and builds a syntax tree
  # => [:begin, [:define, :r, 10], [:*, :pi, [:*, :r, :r]]]
  def read_from_tokens_recursive(tokens, tree = [])
    fail SchemeSyntaxError, "unexpected EOF while reading (did you forget a ')'?)" unless tokens
    token = tokens.first
    next_tokens = tokens.drop(1)
    if token.nil?
      tree.first
    elsif token == '('
      new_sexp, tokens_remaining = read_from_tokens(next_tokens, [])
      read_from_tokens(tokens_remaining, tree + [new_sexp])
    elsif token == ')'
      [tree, next_tokens]
    else
      read_from_tokens(next_tokens, tree + [atom(token)])
    end
  end

  # An iterative (and probably faster) approach to building a syntax tree
  # => [:begin, [:define, :r, 10], [:*, :pi, [:*, :r, :r]]]
  def read_from_tokens_iterative(tokens)
    branches = []
    current_branch = branches
    branch_stack = []
    mutable_tokens = tokens.dup # avoid causing inexplicable bugs due to mutation of argument
    result = loop do
      token = mutable_tokens.shift
      # puts "current branch: #{current_branch.inspect if current_branch}"
      # puts "branches: #{branches.inspect}"
      # puts "next token: #{token}"
      # puts "---"
      if token.nil?
        fail SchemeSyntaxError, "unexpected EOF while reading (did you forget a ')'?)"
      elsif mutable_tokens.empty?
        break branches.any? ? branches.first : atom(token)
      elsif token == '('
        current_branch = []
        branches << current_branch
      elsif token == ')'
        current_branch = branches.pop
        parent_branch  = branches.last
        parent_branch << current_branch
        current_branch = branches.last
      else
        current_branch << atom(token)
      end
    end
    result
  end

  # Casts a token to Ruby's internal representation based on type inference
  # Scheme atoms are represented internally as either Integers, Floats or Symbols
  # depending on the type.
  # Lists are represented by Ruby arrays.
  def atom(token)
    Integer(token)
  rescue ArgumentError
    begin
      Float(token)
    rescue ArgumentError
      token.to_sym
    end
  end

  def parse(program)
    read_from_tokens(tokenize(program))
  end

  #### Environment ####

  # Implemented functions:
  # atom?, eq?, car, cdr, cons,
  # +, -, *, /, >, <
  # Constants:
  # :true, :false
  def initialize(reader_type = :recursive, option_env = {})
    fail ArgumentError, "reader_type must be :recursive or :iterative" unless [:recursive, :iterative].include? reader_type
    @env = {
      :pi       => Math::PI,
      :+        => ->(*args) { args.reduce(&:+) },
      :-        => ->(*args) { args.reduce(&:-) },
      :*        => ->(*args) { args.reduce(&:*) },
      :/        => ->(*args) { args.reduce(&:/) },
      :>        => ->(arg1, arg2) { arg1 > arg2 },
      :begin    => ->(*sexps) { sexps.each {|s| eval_s(s)}; sexps.last },
      :<        => ->(arg1, arg2) { arg1 < arg2 },
      :atom?    => ->(sexp)  { !sexp.is_a?(Array) },
      :eq?      => ->(arg1, arg2) { arg1.hash == arg2.hash },
      :car      => ->(list) { list.empty? ? raise(EmptyListError, "car is defined only for non-empty lists") : list.first },
      :cdr      => ->(list) { list.empty? ? raise(EmptyListError, "car is defined only for non-empty lists") : list.drop(1) },
      :cons     => ->(sexp, list) { [sexp] + list },
      :eval     => ->(sexp) { eval_s(sexp) },
      :true     => true,
      :false    => false,
      :null     => nil
    }.merge(option_env)
    @env.default = :null

    self.class.instance_eval("alias_method :read_from_tokens, :read_from_tokens_#{reader_type}")
  end

  #### EVAL ####
  ## Scheme Forms
  # variable reference      var                         symbol interpreted as variable name, value is variable value. e.g. (:define :r 10), :r => 10
  # constant literal        number                      a number evaluates to itself. e.g. 12 => 12
  # quote                   (quote exp)                 return the literal expression, do not evaluate it (evaluation escape). e.g. (:quote (:+ 1 2)) => (:+ 1 2)
  # conditional             (if test on_true on_false)  evaluate test, if true evaluate on_true, otherwise on_false. e.g. (:if (:> 10 20) (:+ 1 1) (:+ 3 3)) ⇒ 6
  # definition              (define var exp)            define a new variable and give it value as the evaluation of exp. e.g. (:define :r 10)
  # procedure call          (proc args...)              if proc is anything other than [if, define, quote] then treat it as a procedure. evaluate proc and all the args, then apply proc to list of arg values. e.g. (:sqrt (:* 2 8)) ⇒ 4.0

  def eval_s(sexp, env = @env)
    if sexp.is_a? Symbol # variable reference
      env[sexp]
    elsif sexp.is_a?(Numeric)
      sexp
    elsif sexp.first == :quote
      sexp.drop(1).first
    elsif sexp.first == :if
      test = sexp[1]
      on_true = sexp[2]
      on_false = sexp[3]
      eval_s(test) ? eval_s(on_true) : eval_s(on_false)
    elsif sexp.first == :define
      var = sexp[1]
      exp = sexp[2]
      env[var] = exp
    else
      # binding.pry
      lambda = eval_s(sexp.first, env)
      fail NullLambdaError, "undefined lambda '#{sexp.first}'" if lambda.nil?
      args = sexp.drop(1).map {|arg| eval_s(arg, env)}
      lambda.call(*args)
    end
  end

  def parseval(string)
    eval_s(parse(string))
  end

  def repl
    while buf = Readline.readline("$ ", true)
      begin
        input_sexp = buf.chomp
        puts "=> #{schemestr(parseval(input_sexp))}"
      rescue NullLambdaError, SchemeSyntaxError => e
        puts e.inspect
      end
    end
  rescue Interrupt
    puts "Goodbye!"
    exit
  end

  # Convert a ruby object into a Scheme-readable string
  def schemestr(exp)
    if exp.is_a? Array
      '(' + exp.join(' ') + ')'
    else
      exp
    end
  end
end

if __FILE__ == $0
  simple = "(* 1 2)"

  puts "Sam's Scheme interpreter v0.1"
  puts "Try this example s-expression: #{simple}"
  Scheme.new.repl
end
