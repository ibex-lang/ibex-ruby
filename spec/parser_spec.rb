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
end
