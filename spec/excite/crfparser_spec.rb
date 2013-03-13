# encoding: UTF-8

module Excite

  describe CRFParser do

    context "text" do

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

    context "html" do

      before do
        @parser = CRFParser.new(:html)
      end

      describe "html training data" do
        TAGGED_HTML = "<author> &lt;li&gt;González-Bailón, S. </author> <date> (2009) </date> <title> &lt;a&gt;Traps on the Web&lt;/a&gt;. </title> <journal> Information, Communication &amp; Society </journal> <volume> 12 (8) </volume> <pages> 1149-1173.&lt;/li&gt; </pages>"

        it "is labeled correctly" do
          toks = @parser.prepare_token_data(TAGGED_HTML, true)

          expected = [
            ['González-Bailón','li','author'],
            [',','li','author'],
            ['S.','li','author'],
            ['(','li','date'],
            ['2009','li','date'],
            [')','li', 'date'],
            ['Traps','a','title'],
            ['on','a','title'],
            ['the','a','title'],
            ['Web','a','title'],
            ['.','li','title'],
            ['Information','li','journal'],
            [',','li','journal'],
            ['Communication','li','journal'],
            ['&','li','journal'],
            ['Society','li','journal'],
            ['12','li','volume'],
            ['(','li','volume'],
            ['8','li','volume'],
            [')','li','volume'],
            ['1149-1173', 'li', 'pages'],
            ['.','li','pages']
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

      describe "html test data" do
        HTML = "<li><b>Author Name</b><br/> (2012) <a>Paper Title.</a><!-- This is a comment -->Journal Title 15:2 123-234.<span>&nbsp;</span></li>"

        it "is stripped of empty tags and comments except for <br>s" do
          toks = @parser.prepare_token_data(HTML)

          toks.each do |tok|
            ['text','br'].include?(tok.node.name).should be_true
            tok.node.parent.name.should_not == 'comment'
            tok.node.parent.name.should_not == 'span'
          end
        end

        it "is tokenized correctly" do
          expected = [
            ['Author','strong'],
            ['Name','strong'],
            [Token::BR_CHAR,'br'],
            ['(', 'li'],
            ['2012', 'li'],
            [')','li'],
            ['Paper','a'],
            ['Title','a'],
            ['.','a'],
            ['Journal','li'],
            ['Title','li'],
            ['15','li'],
            [':2','li'],
            ['123-234','li'],
            ['.','li']
          ]

          toks = @parser.prepare_token_data(HTML)

          toks.length.should == expected.length

          expected.each_with_index do |e, i|
            t = toks[i]
            t.raw.should == e[0]
            @parser.tag_name(toks, i).should == e[1]
          end
        end

      end

    end

  end

end
