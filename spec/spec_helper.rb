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
end

RSpec.configure do |c|
    c.include Helpers
end
