# This file contains all the AST or Abstract Syntax Tree.
module Ibex
    class Visitor; end

    # Base class for every node in the ast
    class Expression
        attr_accessor :filename, :line

        def raise(msg)
            Kernel::raise "#{filename}##{line}: #{msg}"
        end
    end

    # Creates a new Expression subclass with the specified fields.
    # This macro will add a constructor, the clone method, the hash
    # method, a matching == and a visit_CLASS_NAME method to Visitor.
    def self.create_node(name, *fields)
        encoded_name = name.to_s.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
        clazz = Class.new(Expression) do
            attr_accessor *fields

            class_eval %Q(
            def initialize(#{fields.map(&:to_s).join ", "})
                #{fields.map(&:to_s).map{|x| x.include?("body") ? "@#{x} = Expressions.from #{x}" : "@#{x} = #{x}"}.join("\n")}
            end

            def clone
                self.class.new(#{fields.map(&:to_s).map{|x| "(@#{x}.clone rescue @#{x})"}.join(", ")})
            end

            def hash
                [#{fields.map(&:to_s).map{|x| "@#{x}"}.join(", ")}].hash
            end

            def ==(other)
                return false unless other.class == self.class
                eq = true
                #{fields.map(&:to_s).map{|x| "eq &&= @#{x} == other.#{x}"}.join(";")}
                return eq
            end

            def accept(visitor)
                visitor.visit_any(self) || visitor.visit_#{encoded_name}(self)
            end
            )

            Visitor.class_eval %Q(
            def visit_#{encoded_name}(node)
                nil
            end
            )
        end
        Ibex.const_set name.to_s, clazz
    end

    # AST Node for a "Body" that can contain other expressions.
    # This is often started by an indent and ended by an outdent.
    create_node :Expressions, :contents
    class Expressions
        include Enumerable

        def each(&block)
            contents.each &block
        end

        def empty?
            contents.empty?
        end

        def self.from(other)
            return Expressions.new [] if other.nil?
            return other if other.is_a? Expressions
            return Expressions.new other if other.is_a? ::Array
            Expressions.new [other]
        end
    end

    # AST Node for a module def.
    # Grammar:
    # module CONSTANT
    # <newline><indent> CONTENT
    # <newline?><outdent>
    create_node :ModuleDef, :name, :body

    # AST Node for a Use
    # Grammar:
    # use (CONSTANT::)* | ({CONSTANT,*}::)*
    create_node :Use, :path

    # AST Node for accessing of a module function without args.
    # Grammar:
    # (CONSTANT::)* :: IDENTIFIER
    create_node :ModuleFunctionRef, :constant, :name

    # Several AST Nodes for literals that should speak for themselves.
    create_node :IntLiteral, :value
    create_node :FloatLiteral, :value
    create_node :StringLiteral, :value
    create_node :BoolLiteral, :value

    # AST Node for any identifier. At the typing phase, it
    # will be decided if this is a call or a var reference.
    # Grammar:
    # IDENTIFIER
    create_node :Identifier, :value

    # AST Node for a binary operation.
    # Grammar:
    # EXPRESSION OP EXPRESSION
    create_node :Binary, :left, :op, :right

    # AST Node for assignment
    # Grammar
    # TARGET_EXPRESSION OP VALUE_EXPRESSION
    create_node :Assign, :target, :value

    # AST Node for calls with arguments.
    # Grammar:
    # EXPRESSION -> IDENTIFIER | (EXPRESSION, EXPRESSION, ...) -> IDENTIFIER
    create_node :CallArgs, :args # Temporary holder for the (arg, arg...) part
    create_node :Call, :target, :args

    # AST Node for a function definition.
    # Grammar:
    # fn IDENTIFIER
    # fn IDENTIFIER IDENTIFIER: TYPE
    # fn IDENTIFIER IDENTIFIER: TYPE, IDENTIFIER: TYPE, ...
    # fn IDENTIFIER IDENTIFIER: TYPE, IDENTIFIER: TYPE, ... -> TYPE
    create_node :FunctionArg, :name, :given_type
    create_node :FunctionDef, :name, :args, :return_type, :body

    # AST Node for an if statement.
    # Grammar:
    # if EXPRESSION
    # <newline><indent>TRUE_BODY
    # (<newline><outdent>else
    #  <newline><indent>FALSE_BODY)
    create_node :If, :condition, :true_body, :false_body
end
