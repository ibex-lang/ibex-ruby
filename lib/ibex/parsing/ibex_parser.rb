
module Ibex
    def parse(src, file = "unknown source")
        Ibex.parse src, file
    end

    def self.parse(src, file = "unknown source")
        parser = create_parser src, file
        contents = []
        until (node = parser.parse_expression).nil?
            contents << node
        end
        Expressions.from contents
    end

    def create_parser(src, file = "unknown source")
        Ibex.create_parser src, file
    end

    def self.create_parser(src, file = "unknown source")
        Parser.new(src, file) do
            expr -> tok { tok.is?("true") || tok.is?("false") } do
                BoolLiteral.new consume.value == "true"
            end

            expr -> tok { tok.is_integer? } do
                IntLiteral.new consume.value.to_i
            end

            expr -> tok { tok.is_float? } do
                FloatLiteral.new consume.value.to_f
            end

            expr -> tok { tok.is_string? } do
                StringLiteral.new consume.value[1..-2]
            end

            expr -> tok { tok.is_identifier? } do
                Identifier.new consume.value
            end

            expr -> tok { tok.is_keyword? "module" } do
                ModuleDef.new expect_next_and_consume(:constant).value, parse_body
            end
        end
    end

    class Parser
        def create_binary_parser(prec, right_associative = false)
            return lambda do |left|
                Binary.new(left, consume.value, expect_expression(right_associative ? prec - 1 : prec))
            end
        end

        def parse_body(consume_newline = true)
            unless token.is_indent?
                node = parse_expression
                raise_error "Did you forget to indent? Expected node here:", token unless node
                return node
            end

            expect_and_consume(:indent)

            contents = []
            until token.is_outdent? || token.is_eof?
                contents << parse_expression
            end
            next_token # Consume outdent or eof
            next_token if token.is_newline? && consume_newline

            Expressions.from contents
        end
    end
end
