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
end
