# encoding: UTF-8

describe CRFParser do

  before do
    @parser = CRFParser.new
  end

  describe "normalize_input_author" do

    it "handles blank" do
      @parser.normalize_input_author(nil).should be_nil
      @parser.normalize_input_author('').should be_nil
    end

    it "handles name with junk punctuation" do
      res = @parser.normalize_input_author("'Gertjan van Noord'")
      res.should == ['gertjan', 'van', 'noord']
    end

  end

end
