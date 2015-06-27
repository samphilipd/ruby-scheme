require 'pry'

program = "(begin (define r 10) (* pi (* r r)))"

# Splits a string of characters into an array of tokens
def tokenize(chars)
  chars.gsub('(', ' ( ').gsub(')', ' ) ').split
end

# Reads from a list of tokens and builds a syntax tree
def read_from_tokens(tokens)
  fail SyntaxError, "unexpected EOF while reading" if tokens.empty?
  token = tokens.shift
  case token
  when '('
    tree = []
    loop do
      subtoken = tokens.first
      if subtoken == ')'
        tokens.shift
        break
      end
      tree << read_from_tokens(tokens)
    end
    tree
  when ')'
    fail SyntaxError, "unexepected )"
  else
    atom(token)
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

binding.pry
puts read_from_tokens(tokenize(program))
