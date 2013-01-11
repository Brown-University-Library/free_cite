# encoding: UTF-8

require 'free_cite/postprocessor'

describe Postprocessor do

  describe "normalize_title" do

    it "strips whitespace" do
      normalize(' a title .').should == 'a title'
    end

    it "strips punctuation" do
      normalize('(a title) ').should == 'a title'
    end

    it "strips leading numerals" do
      normalize('1. A title').should == 'A title'
    end

    it "doesn't strip numerals part of the title" do
      normalize('1 is the best number of titles').should == '1 is the best number of titles'
    end

    it "strips leading roman numerals" do
      normalize('xiv. A title').should == 'A title'
    end

    it "doesn't strip roman numeral-like title starts" do
      normalize('IVs are needles not titles').should == 'IVs are needles not titles'
    end

    it "strips leading enumerating letters" do
      normalize('A. My title').should == 'My title'
    end

    it "doesn't strip leading single letters" do
      normalize('A title').should == 'A title'
    end

    it "extracts title from between quotes" do
      normalize('"A title" which is cool').should == 'A title'
    end

    it "doesn't reduce title to quote part" do
      normalize('This title comments on "some other title": a crappy work').should == 'This title comments on "some other title": a crappy work'
    end

    def normalize(title)
      hsh = { "title" => title }
      CRFParser.new.normalize_title(hsh)
      hsh["title"]
    end

  end

end
