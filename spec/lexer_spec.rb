require "spec_helper"

describe Lexer do
    it "lexes floats" do
        expect(lex "1.0").to eq [:float, "1.0"]
        expect(lex "12.0").to eq [:float, "12.0"]
        expect(lex "12.14").to eq [:float, "12.14"]
        expect(lex "0.1").to eq [:float, "0.1"]
        expect(lex "0.12").to eq [:float, "0.12"]
    end

    it "lexes integers" do
        expect(lex "1").to eq [:integer, "1"]
        expect(lex "+1").to eq [:integer, "+1"]
        expect(lex "-1").to eq [:integer, "-1"]
        expect(lex "0").to eq [:integer, "0"]
        expect(lex "01").to eq [:integer, "01"]
        expect(lex "1L").to eq [:integer, "1L"]
    end

    it "lexes strings" do
        expect(lex "'Test'").to eq [:string, "'Test'"]
        expect(lex '"Test"').to eq [:string, '"Test"']
        expect(lex "''").to eq [:string, "''"]
        expect(lex '""').to eq [:string, '""']
    end

    pending "lexes strings with escaped characters", "regex seems to be broken" do
        expect(lex "\\\"foo").to eq [:string, "\\\"foo"]
        expect(lex '\\\'foo').to eq [:string, '\\\'foo']
    end

    it "lexes 'specials'" do
        ["::", ":", "->", ",", "[", "]", "{", "}", "=", "|"].each do |special|
            expect(lex special).to eq [:special, special]
        end
    end

    it "lexes operators" do
        ["+", "-", "/", "*", ">", ">=", "<", "<=", "==", "!=", "&&", "||"].each do |op|
            expect(lex op).to eq [:operator, op]
        end
    end

    it "lexes constants" do
        expect(lex "Foo").to eq [:constant, "Foo"]
        expect(lex "F").to eq [:constant, "F"]
        expect(lex "F_A").to eq [:constant, "F_A"]
        expect(lex "F____21").to eq [:constant, "F____21"]
    end

    it "lexes identifiers" do
        expect(lex "foo").to eq [:identifier, "foo"]
        expect(lex "_").to eq [:identifier, "_"]
        expect(lex "_0").to eq [:identifier, "_0"]
        expect(lex "__fooSBA_b10_axz01S").to eq [:identifier, "__fooSBA_b10_axz01S"]
    end

    it "lexes keywords" do
        Lexer::KEYWORDS.each do |kw|
            expect(lex kw).to eq [:keyword, kw]
        end
    end

    it "keeps track of newlines and line numbers" do
        lexer = Lexer.new "lexer_spec", "1\n2\n3\n\n4"

        expect(lexer.next_token.line_num).to eq 1
        expect(lexer.next_token.kind).to eq :newline
        expect(lexer.next_token.line_num).to eq 2
        expect(lexer.next_token.kind).to eq :newline
        expect(lexer.next_token.line_num).to eq 3
        expect(lexer.next_token.kind).to eq :newline
        # Note that there is no newline check here. The lexer only emits the newline once.
        expect(lexer.next_token.line_num).to eq 5
    end

    it "keeps track of indentation levels" do
        lexer = Lexer.new "lexer_spec", %Q(
            A
              B
                   C
              B
            A
                    B
        )

        expect(lexer.next_token.kind).to eq :newline
        expect(lexer.next_token.kind).to eq :indent
        expect(lexer.next_token.kind).to eq :constant # A
        expect(lexer.next_token.kind).to eq :newline
        expect(lexer.next_token.kind).to eq :indent
        expect(lexer.next_token.kind).to eq :constant # B
        expect(lexer.next_token.kind).to eq :newline
        expect(lexer.next_token.kind).to eq :indent
        expect(lexer.next_token.kind).to eq :constant # C
        expect(lexer.next_token.kind).to eq :newline
        expect(lexer.next_token.kind).to eq :outdent
        expect(lexer.next_token.kind).to eq :constant # B
        expect(lexer.next_token.kind).to eq :newline
        expect(lexer.next_token.kind).to eq :outdent
        expect(lexer.next_token.kind).to eq :constant # A
        expect(lexer.next_token.kind).to eq :newline
        expect(lexer.next_token.kind).to eq :indent
        expect(lexer.next_token.kind).to eq :constant # B
    end
end
