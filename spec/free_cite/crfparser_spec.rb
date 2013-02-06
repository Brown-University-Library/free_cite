# encoding: UTF-8

module FreeCite

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

    describe "html training data" do
      TAGGED_HTML = "<author> &lt;li&gt;González-Bailón, S. </author> <date> (2009) </date> <title> &lt;a&gt;Traps on the Web&lt;/a&gt;. </title> <journal> Information, Communication &amp; Society </journal> <volume> 12 (8) </volume> <pages> 1149-1173.&lt;/li&gt; </pages>"

      it "is labeled correctly" do
        toks = CRFParser.new(:html).prepare_token_data(TAGGED_HTML, true)

        expected = [
          ['González-Bailón,','li','author'],
          ['S.','li','author'],
          ['(2009)','li', 'date'],
          ['Traps','a','title'],
          ['on','a','title'],
          ['the','a','title'],
          ['Web','a','title'],
          ['.','li','title'],
          ['Information,','li','journal'],
          ['Communication','li','journal'],
          ['&','li','journal'],
          ['Society','li','journal'],
          ['12','li','volume'],
          ['(8)','li','volume'],
          ['1149-1173.', 'li', 'pages']
        ]

        toks.length.should == expected.length

        expected.each_with_index do |e, i|
          t = toks[i]
          t.raw.should == e[0]
          t.node.parent.name.should == e[1]
          t.label.should == e[2]
        end
      end

    end

  end

end
