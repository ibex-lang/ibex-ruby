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
end
