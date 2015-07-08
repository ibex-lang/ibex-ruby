
module Ibex
    class Parser
        def parse_type
            # Tuples
            if token.is? "(" then
                next_token # Consume (

                types = []
                until token.is? ")"
                    name = token.is_identifier? ? consume.value : nil
                    expect_and_consume(":") if name

                    types << [name, parse_type]
                    raise_error "Expected , or ) in tuple signature here:", token unless token.is?(",") || token.is?(")")
                    next_token if token.is? ","
                end

                next_token # Consume )
                return UnresolvedTupleType.new types
            end

            # Array
            if token.is? "[" then
                expect_next_and_consume "]"
                return UnresolvedArrayType.new parse_type
            end

            # Function
            if token.is_keyword? "fn" then
                next_token # Consume fn

                arg_types = []
                if token.is? "(" then
                    next_token # Consume (
                    until token.is? ")"
                        arg_types << parse_type
                        raise_error "Expected , or ) in function signature", token unless token.is?(")") || token.is?(",")
                        next_token if token.is? ","
                    end
                    next_token # Consume )
                elsif token.is_constant? || token.is_keyword?("fn") || token.is?("(") || token.is?("[") then
                    arg_types << parse_type
                end

                return_type = nil
                if token.is? "->" then
                    next_token # Consume ->
                    return_type = parse_type
                end

                return UnresolvedFunctionType.new arg_types, return_type
            end

            # Named
            names = [expect_and_consume(:constant).value]
            while token.is? "::"
                names << expect_next_and_consume(:constant).value
            end
            return UnresolvedNamedType.new names
        end
    end

    class UnresolvedType
        def resolve(visitor)
            raise "Unimplemented UnresolvedType#resolve for class #{self.class.name}!"
        end
    end

    class UnresolvedNamedType < UnresolvedType
        attr_reader :names

        def initialize(names)
            @names = names
        end

        def to_s
            @names.join "::"
        end

        def ==(other)
            other.class == UnresolvedNamedType && other.names == names
        end

        def clone
            UnresolvedNamedType.new names.clone
        end
    end

    class UnresolvedTupleType < UnresolvedType
        # Types is an array of arrays. (a: Foo, Bar) results in a types of [[a, Foo], [nil, Bar]]
        attr_reader :types

        def initialize(types)
            @types = types
        end

        def to_s
            "(" + types.map{|x| x.first ? "#{x.first}: #{x.last.to_s}" : x.last.to_s}.join(", ") + ")"
        end

        def ==(other)
            other.class == UnresolvedTupleType && other.types == types
        end

        def clone
            UnresolvedTupleType.new types.map{|x| [x.first, x.last.clone]}
        end
    end

    class UnresolvedArrayType < UnresolvedType
        attr_reader :element_type

        def initialize(el_type)
            @element_type = el_type
        end

        def to_s
            "[]#{element_type}"
        end

        def ==(other)
            other.class == UnresolvedArrayType && other.element_type == element_type
        end

        def clone
            UnresolvedArrayType.new element_type.clone
        end
    end

    class UnresolvedFunctionType < UnresolvedType
        attr_reader :arg_types, :return_type

        def initialize(args, return_type)
            @arg_types = args
            @return_type = return_type
        end

        def to_s
            if arg_types.size == 0 && return_type.nil? then
                "fn"
            elsif arg_types.size > 0 && return_type.nil? then
                "fn (#{arg_types.map(&:to_s).join(", ")})"
            else
                "fn (#{arg_types.map(&:to_s).join(", ")}) -> #{return_type.to_s}"
            end
        end

        def ==(other)
            other.class == UnresolvedFunctionType && other.arg_types == arg_types && other.return_type == return_type
        end

        def clone
            UnresolvedFunctionType.new arg_types.map(&:clone), return_type ? return_type.clone : nil
        end
    end
end
