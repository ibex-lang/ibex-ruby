# Import Ibex
require File.expand_path("../../lib/ibex",  __FILE__)
include Ibex

module Helpers
    def lex(str)
        lex = Lexer.new "lexer_spec", str
        tokens = []
        until (t = lex.next_token).is_eof?
            tokens << [t.kind, t.value]
        end
        tokens.size == 1 ? tokens.first : tokens
    end

    # Parses a type
    def parse_type(str)
        Parser.new(str, "spec").parse_type
    end

    # Parses a single expression.
    def parse(str)
        Ibex.create_parser(str, "spec").parse_expression
    end

    # Parses until EOF is reached.
    def parse!(str)
        Ibex.parse str, "spec"
    end
end

class Fixnum
    def literal
        IntLiteral.new self
    end
end

class TrueClass
    def literal
        BoolLiteral.new true
    end
end

class FalseClass
    def literal
        BoolLiteral.new false
    end
end

class String
    def literal
        StringLiteral.new self
    end

    def ident
        Identifier.new self
    end

    def type
        UnresolvedNamedType.new [self]
    end
end

class Array
    def type
        UnresolvedNamedType.new self
    end

    def tuple
        UnresolvedTupleType.new self
    end

    def fn
        UnresolvedFunctionType.new self[0...-1], last
    end
end

class UnresolvedType
    def array
        UnresolvedArrayType.new self
    end
end

class Float
    def literal
        FloatLiteral.new self
    end
end

RSpec.configure do |c|
    c.include Helpers
end
