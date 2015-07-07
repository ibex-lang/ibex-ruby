
module Ibex
    # This is the main lexer for Ibex, responsible for cutting up the source code
    # into different parts that are recognized by the parser. New syntax can simply
    # be added by adding a new regex or a new keyword.
    class Lexer
        RULES = {
            # Regex for matching token  => token kind
            /\A[+-]?[0-9]+\.[0-9][0-9]*/          => :float,
            /\A[+-]?[0-9]+[L]?/                   => :integer,
            /\A(["'])(\\?.)*?\1/                  => :string,

            /\A\(/                                => :lparen,
            /\A\)/                                => :rparen,

            /\A::/                                => :special,
            /\A:/                                 => :special,
            /\A->/                                => :special,
            /\A,/                                 => :special,
            /\A\[/                                => :special,
            /\A\]/                                => :special,
            /\A\{/                                => :special,
            /\A\}/                                => :special,

            /\A\+/                                => :operator,
            /\A\//                                => :operator,
            /\A\-/                                => :operator,
            /\A\*/                                => :operator,
            /\A\./                                => :operator,
            /\A%/                                 => :operator,

            /\A&&/                                => :operator,
            /\A&/                                 => :operator,
            /\A\|\|/                              => :operator,
            /\A>=?/                               => :operator,
            /\A<=?/                               => :operator,

            /\A[A-Z][_0-9a-zA-Z]*/                => :constant,
            /\A[_a-zA-Z][_0-9a-zA-Z]*/            => :identifier,

            # Note that the order of these matters! This lexer is lazy, so it will always match `=` over `==` unless we specify `==` first.
            /\A==/                                => :operator,
            /\A=/                                 => :special,
            /\A!=/                                => :operator,
            /\A\|/                                => :special
        }
        KEYWORDS = ["fn", "match", "if", "else", "true", "false", "null", "use", "match", "module", "type", "as", "new", "extern", "let"]

        attr_reader :filename, :source

        def initialize(file, source)
            @filename = file
            @source = source

            @index = 0
            @current_line = 1
            @current_column = 0
            @indentation_levels = [0]
            @token_queue = []
        end

        def next_token
            return @token_queue.pop unless @token_queue.empty?
            return Token.new(:eof, nil, 0, 0) if @index >= @source.length

            # If we only have a blank line, dont assume it is an outdent but simply skip the line.
            if source[@index] == "\n" && @index + 1 < @source.length && source[@index + 1] == "\n" then
                @index += 1
                @current_line += 1
                return next_token
            end

            if source[@index] == "\n" then
                @index += 1
                @current_line += 1
                @current_column = 0

                whitespace = 0
                while (char = next_char) == " "
                    whitespace += 1
                end

                @index -= 1
                @current_column -= 1

                if whitespace > @indentation_levels.last then
                    @token_queue << Token.new(:indent, nil, 0, @current_line)
                    @indentation_levels.push whitespace
                end

                while whitespace < @indentation_levels.last
                    @token_queue << Token.new(:outdent, nil, 0, @current_line)
                    @indentation_levels.pop
                    raise "Impossible." if @indentation_levels.last < whitespace
                end

                @token_queue << Token.new(:newline, "\n", 0, @current_line)

                return next_token
            end

            # Skip whitespace
            while next_char == " "
            end

            @index -= 1
            @current_column -= 1

            RULES.each do |matcher, kind|
                if @source[@index..-1] =~ matcher then
                    if kind == :identifier && KEYWORDS.include?($&) then
                        kind = :keyword
                    end

                    tok = Token.new kind, $&, @current_column, @current_line
                    @current_column += $&.length
                    @index += $&.length

                    return tok
                end
            end

            raise "Don't know what do to with #{@source[@index..@index + 5]}"
        end

        private
        def next_char
            char = source[@index]
            @index += 1

            if char == "\n"
                @current_line += 1
                @current_column = 0
            else
                @current_column += 1
            end

            char
        end
    end
end
