
module Ibex
    # This is a token. A token is emitted from the Lexer for every
    # interesting part.
    class Token
        attr_accessor :kind, :value, :column, :line_num

        def initialize(kind, value, col, line)
            @kind = kind
            @value = value
            @column = col
            @line_num = line
        end

        def is?(val)
            value == val
        end

        def is_kind?(type)
            kind == type
        end

        # This allows us to do `token.is_keyword?("a")`, which will
        # check if its kind is :keyword and its value is "a".
        def method_missing(name, *args)
            return super unless name =~ /is_(.*)\?/
            func_kind = /is_(.*)\?/.match(name).captures.first
            matches = func_kind.to_sym == kind
            matches = (matches && is?(args.first)) if args.size == 1
            return matches
        end
    end
end
