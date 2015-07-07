
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
        end
    end
end
