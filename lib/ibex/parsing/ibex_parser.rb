
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

            expr -> tok { tok.is_keyword? "use" } do
                next_token # Consume use
                paths = [expect_and_consume(:constant).value]

                while token.is?("::")
                    next_token # Consume ::
                    if token.is? "{" then
                        next_token # Consume {

                        parts = []
                        until token.is? "}"
                            parts << expect_and_consume(:constant).value
                            raise_error "Expected '}' or ',' here:", token unless token.is?(",") || token.is?("}")
                            next_token if token.is? "," # Consume ,
                        end
                        next_token # Consume }

                        paths << parts
                    else
                        paths << expect_and_consume(:constant).value
                    end
                end

                Use.new paths
            end

            expr -> tok { token.is_constant? } do
                const_names = [consume.value]
                method_name = nil

                while token.is? "::"
                    next_token # Consume ::

                    if token.is_constant?
                        const_names << consume.value
                    else
                        method_name = expect_and_consume(:identifier).value
                    end
                end
                raise_error "Expected method name after #{const_names.join "::"}, here:", token unless method_name

                ModuleFunctionRef.new const_names, method_name
            end

            infix 12, -> x { x.is_operator? "+" }, &create_binary_parser(12)
            infix 12, -> x { x.is_operator? "-" }, &create_binary_parser(12)
            infix 13, -> x { x.is_operator? "*" }, &create_binary_parser(13)
            infix 13, -> x { x.is_operator? "/" }, &create_binary_parser(13)
            infix 11, -> x { x.is_operator? "%" }, &create_binary_parser(11)

            infix  5, -> x { x.is_operator? "&&" }, &create_binary_parser(5)
            infix  4, -> x { x.is_operator? "||" }, &create_binary_parser(4)
            infix 10, -> x { x.is_operator? "<"  }, &create_binary_parser(10)
            infix 10, -> x { x.is_operator? "<=" }, &create_binary_parser(10)
            infix 10, -> x { x.is_operator? ">"  }, &create_binary_parser(10)
            infix 10, -> x { x.is_operator? ">=" }, &create_binary_parser(10)

            infix  9, -> x { x.is_operator? "==" }, &create_binary_parser(9)
            infix  9, -> x { x.is_operator? "!=" }, &create_binary_parser(9)
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
