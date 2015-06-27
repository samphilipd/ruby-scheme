require 'pry'

program = "(begin (define r 10) (* pi (* r r)))"
simple = "(* 1 2)"

# Splits a string of characters into an array of tokens, outputting e.g.
# => ["(", "begin", "(", "define", "r", "10", ")", "(", "*", "pi", "(", "*", "r", "r", ")", ")", ")"]
def tokenize(chars)
  chars.gsub('(', ' ( ').gsub(')', ' ) ').split
end

# Reads from a list of tokens and builds a syntax tree
# => [:begin, [:define, :r, 10], [:*, :pi, [:*, :r, :r]]]
def read_from_tokens(tokens, tree = [])
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

# Casts a token to Ruby's internal representation based on type inference
def atom(token)
  Integer(token)
rescue ArgumentError
  begin
    Float(token)
  rescue ArgumentError
    token.to_sym
  end
end

puts read_from_tokens(tokenize(program)).inspect
