require "spec_helper"

describe Parser do
    it "parses literals" do
        expect(parse "10").to eq 10.literal
        expect(parse "true").to eq true.literal
        expect(parse "false").to eq false.literal
        expect(parse "3.14").to eq 3.14.literal

        expect(parse "'foo'").to eq "foo".literal
        expect(parse "'foo'").to eq "foo".literal

        expect(parse "foo").to eq "foo".ident
    end

    it "parses types" do
        expect(parse_type "Foo").to eq "Foo".type
        expect(parse_type "Foo::Bar").to eq ["Foo", "Bar"].type

        expect(parse_type "[]Foo").to eq "Foo".type.array
        expect(parse_type "[]Foo::Bar").to eq ["Foo", "Bar"].type.array
        expect(parse_type "[][]Foo").to eq "Foo".type.array.array

        expect(parse_type "fn").to eq [nil].fn
        expect(parse_type "fn Foo").to eq ["Foo".type, nil].fn
        expect(parse_type "fn (Foo, Bar)").to eq ["Foo".type, "Bar".type, nil].fn
        expect(parse_type "fn Foo -> Bar").to eq ["Foo".type, "Bar".type].fn
        expect(parse_type "fn (Foo, Bar) -> Baz").to eq ["Foo".type, "Bar".type, "Baz".type].fn

        expect(parse_type "()").to eq [].tuple
        expect(parse_type "(Foo)").to eq [[nil, "Foo".type]].tuple
        expect(parse_type "(foo: Foo)").to eq [["foo", "Foo".type]].tuple
        expect(parse_type "(Foo, Bar)").to eq [[nil, "Foo".type], [nil, "Bar".type]].tuple
        expect(parse_type "(foo: Foo, bar: Bar)").to eq [["foo", "Foo".type], ["bar", "Bar".type]].tuple
        expect(parse_type "(foo: Foo, Bar)").to eq [["foo", "Foo".type], [nil, "Bar".type]].tuple
    end

    it "parses a module def" do
        src = %Q(
        module Foo
            3
            1
        ).strip

        expect(parse src).to eq ModuleDef.new "Foo", [3.literal, 1.literal].body
    end

    it "parses a use" do
        expect(parse "use A").to eq Use.new ["A"]
        expect(parse "use A::B").to eq Use.new ["A", "B"]
        expect(parse "use A::{B}").to eq Use.new ["A", ["B"]]
        expect(parse "use A::{A, B}").to eq Use.new ["A", ["A", "B"]]
    end

    it "parses a ModuleFunctionRef" do
        expect(parse "A::b").to eq ModuleFunctionRef.new ["A"], "b"
        expect(parse "A::B::c").to eq ModuleFunctionRef.new ["A", "B"], "c"
        expect(parse "A::A::c").to eq ModuleFunctionRef.new ["A", "A"], "c"
    end

    it "parses all the operators" do
        ["+", "-", "/", "*", ">", ">=", "<", "<=", "==", "!=", "&&", "||"].each do |op|
            expect(parse "3 #{op} 1").to eq Binary.new 3.literal, op, 1.literal
        end
    end

    it "parses operators with precedence awareness" do
        expect(parse "3 + 1 * 4").to eq Binary.new(3.literal, "+", Binary.new(1.literal, "*", 4.literal))
        expect(parse "3 / 1 * 4").to eq Binary.new(Binary.new(3.literal, "/", 1.literal), "*", 4.literal)
    end

    it "parses assignments with precedence awareness" do
        expect(parse "a = 3").to eq Assign.new "a".ident, 3.literal
        expect(parse "a = 3 * 1").to eq Assign.new("a".ident, Binary.new(3.literal, "*", 1.literal))
    end

    it "parses calls" do
        expect(parse "()").to eq CallArgs.new []
        expect(parse "(3)").to eq 3.literal
        expect(parse "(a, b)").to eq CallArgs.new ["a".ident, "b".ident]

        expect(parse "() -> foo").to eq Call.new "foo".ident, []
        expect(parse "a -> foo").to eq Call.new "foo".ident, ["a".ident]
        expect(parse "(1, 2) -> foo").to eq Call.new "foo".ident, [1.literal, 2.literal]

        expect(parse "a -> b -> c").to eq Call.new("c".ident, [Call.new("b".ident, ["a".ident])])
        expect(parse "a -> Foo::bar").to eq Call.new(ModuleFunctionRef.new(["Foo"], "bar"), ["a".ident])
    end

    it "parses function defs" do
        src = %Q(
        fn foo
          1
        ).strip
        expect(parse src).to eq FunctionDef.new "foo", [], nil, [1.literal].body

        src = %Q(
        fn foo a: I32
          1
        ).strip
        expect(parse src).to eq FunctionDef.new "foo", [FunctionArg.new("a", "I32".type)], nil, [1.literal].body

        src = %Q(
        fn foo (a: I32, b: F32)
          1
        ).strip
        expect(parse src).to eq FunctionDef.new "foo", [FunctionArg.new("a", "I32".type), FunctionArg.new("b", "F32".type)], nil, [1.literal].body

        src = %Q(
        fn foo a: I32 -> Bool
          1
        ).strip
        expect(parse src).to eq FunctionDef.new "foo", [FunctionArg.new("a", "I32".type)], "Bool".type, [1.literal].body

        src = %Q(
        fn foo (a: I32, b: F32) -> Bool
          1
        ).strip
        expect(parse src).to eq FunctionDef.new "foo", [FunctionArg.new("a", "I32".type), FunctionArg.new("b", "F32".type)], "Bool".type, [1.literal].body
    end
end
