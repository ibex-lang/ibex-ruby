
module Ibex
    # This is a "parsing" framework. It does not have methods that are
    # specific for Ibex, but rather provides an easy way to handle parsing
    # of expressions, including infixes with precedence.
    class Parser
        def initialize(src, file = "src", &block)
            @source = src
            @file = file
            @lexer = Lexer.new file, src
            @current_token = @lexer.next_token

            @expression_parsers = {} #Predicate: Void -> Expression
            @infix_parsers      = {} #Predicate: [Precedence, Void -> Expression]

            instance_exec &block if block
        end

        # Advances the token
        def next_token
            @current_token = @lexer.next_token
        end

        # Gets the current token
        def current_token
            @current_token
        end
        alias :token :current_token

        # Advances the token and returns the previous token
        def consume
            cur = @current_token
            next_token
            return cur
        end

        # Adds a new expression parser with the provided Predicate
        # and block.
        def expr(matcher, &block)
            @expression_parsers[matcher] = block
        end

        # Adds a new infix parser with the provided precedence,
        # Predicate and block.
        def infix(precedence, matcher, &block)
            @infix_parsers[matcher] = [precedence, block]
        end

        # Parses the expression at the current token, or nil
        # if not applicable.
        def parse_expression(precedence = 0)
            # Skip the newline if there is one.
            if current_token.is_newline?
                next_token
                return parse_expression precedence
            end

            ret, line = nil, current_token.line_num
            @expression_parsers.each do |matcher, parser|
                next unless matcher.call(current_token) && ret.nil?

                left = instance_exec &parser
                while precedence < cur_token_precedence
                    _, contents = @infix_parsers.select{|key, val| key.call @current_token}.first
                    left = instance_exec left, &contents.last
                end
                ret = left
            end
            add_line_info(line, ret) if ret
            ret
        end

        # Parses an expression, or raises an error
        def expect_expression(prec = 0)
            expr = parse_expression prec
            raise_error "Expected expression here:", token unless expr
            expr
        end

        # Expects the provided values at the current token, or raises an error
        def expect(one, two = nil)
            check_eq token, one, two
        end

        # Expects the provided values at the current token, or raises an error.
        # If matched, the token is advanced and the token that was matched against
        # is returned.
        def expect_and_consume(one, two = nil)
            ret = expect one, two
            next_token
            return ret
        end

        # Expects the provided values at the next token, or raises an error.
        def expect_next(one, two = nil)
            check_eq next_token, one, two
        end

        # Expects the provided values at the next token, or raises an error.
        # If matched, the token is advanced and the token that was matched against
        # is returned.
        def expect_next_and_consume(one, two = nil)
            ret = expect_next one, two
            next_token
            return ret
        end

        def raise_error(message, line, col = 0, length = 0)
            line, col, length = line.line_num, line.column, (line.value.length rescue 1) if line.is_a? Token

            header = "#{@file}##{line}: "
            str = "Error: #{message}\n"
            str << "#{@file}##{line - 1}: #{@source.lines[line - 2].chomp}\n" if line > 1
            str << "#{header}#{(@source.lines[line - 1] || "").chomp}\n"
            str << (' ' * (col + header.length))
            str << '^' << ('~' * (length - 1)) << "\n"
            str << "#{@file}##{line + 1}: #{@source.lines[line].chomp}\n" if @source.lines[line]
            raise str
        end

        private
        # Private method that checks if the current token is valid for
        # the specified values, whether they are symbols or strings.
        def check_eq(tok, one, two)
            one_matches = one.is_a?(Symbol) ? tok.is_kind?(one) : tok.is?(one)
            two_matches = two ? two.is_a?(Symbol) ? tok.is_kind?(two) : tok.is?(two) : true
            return tok if one_matches and two_matches

            type = one.is_a?(Symbol) ? one : two.is_a?(Symbol) ? two : nil
            val = one.is_a?(String) ? one : two.is_a?(String) ? two : nil

            err_msg = "Expected token"
            err_msg << " of type #{type.to_s.upcase}" if type
            err_msg << " with value of '#{val.to_s}'" if val
            err_msg << " here:"
            raise_error err_msg, tok
        end

        # Gets the precedence of the token currently looked at, or 0
        # if not applicable.
        def cur_token_precedence
            filtered = @infix_parsers.select{|key, val| key.call @current_token}
            return 0 if filtered.size == 0
            filtered.first.last[0]
        end

        # Recursively adds information about the current line and file
        # to any constructed AST nodes, to prevent the bother of doing
        # it manually.
        def add_line_info(line, node)
            return if node.is_a?(Expressions)
            return unless node.is_a?(Expression) || node.is_a?(::Enumerable)

            if node.is_a?(::Enumerable) then
                node.each {|el| add_line_info(line, el)}
            else
                node.line = line
                node.filename = @file
                node.instance_variables.each do |var|
                    add_line_info(line, node.instance_variable_get(var))
                end
            end
        end
    end
end
