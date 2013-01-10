# encoding: UTF-8

describe Citation do

  it "handles nil" do
    Citation.parse(nil).should be_nil
  end

  it "handles empty string" do
    Citation.parse("").should be_nil
  end

  it "handles string that used to break model" do
    Citation.parse("[if gte mso 10]>\r\n<style>\r\n /* Style Definitions */\r\n table.MsoNormalTable\r\n\t{mso-style-name:\"Table Normal\";\r\n\tmso-tstyle-rowband-size:0;\r\n\tmso-tstyle-colband-size:0;\r\n\tmso-style-noshow:yes;\r\n\tmso-style-priority:99;\r\n\tmso-style-parent:\"\";\r\n\tmso-padding-alt:0in 5.4pt 0in 5.4pt;\r\n\tmso-para-margin:0in;\r\n\tmso-para-margin-bottom:.0001pt;\r\n\tmso-pagination:widow-orphan;\r\n\tfont-size:10.0pt;\r\n\tfont-family:\"Times New Roman\",\"serif\";}\r\n</style>\r\n<![endif]").should be_nil
  end

  it "handles non-ASCII unicode characters" do
    hash = Citation.parse("Okuda, Michael, and Denise Okuda. 1993. Star trek chronology » The history of the future りがと. New York: Pocket Books.")
    hash[:title].should == "Star trek chronology » The history of the future"
  end

  it "returns nil for non-citation string" do
    Citation.parse("Recently while contemplating hosting options for my startup I decided to take a look at Heroku.").should be_nil
  end

  it "parses title for APA journal article" do
    hash = Citation.parse("Devine, P. G., & Sherman, S. J. (1992). Intuitive versus rational judgment and the role of stereotyping in the human condition: Kirk or Spock? Psychological Inquiry, 3(2), 153-159. doi:10.1207/s15327965pli0302_13")
    hash[:title].should == "Intuitive versus rational judgment and the role of stereotyping in the human condition: Kirk or Spock"
  end

  it "parses title for Turabian journal article" do
    hash = Citation.parse("Wilcox, Rhonda V. 1991. Shifting roles and synthetic women in Star trek: The next generation. Studies in Popular Culture 13 (June): 53-65.")
    hash[:title].should == 'Shifting roles and synthetic women in Star trek: The next generation'
  end

  it "parses title for Turabian book" do
    hash = Citation.parse("Okuda, Michael, and Denise Okuda. 1993. Star trek chronology: The history of the future. New York: Pocket Books.")
    hash[:title].should == "Star trek chronology: The history of the future"
  end

  it "parses title for MLA journal article" do
    pending "Doesn't work quite right, includes journal title in article title"
    hash = Citation.parse('Hodges, F. M. "The Promised Planet: Alliances and Struggles of the Gerontocracy in American Television Science Fiction of the 1960s." Aging Male 6.3 (2003)')
    hash[:title].should == "The Promised Planet: Alliances and Struggles of the Gerontocracy in American Television Science Fiction of the 1960s."
  end

  it "parses title for MLA newspaper article" do
    hash = Citation.parse('Di Rado, Alicia. "Trekking through College: Classes Explore Modern Society Using the World of Star Trek." Los Angeles Times 15 Mar. 1995: A3+. Print.')
    hash[:title].should == 'Trekking through College: Classes Explore Modern Society Using the World of Star Trek'
  end

  it "parses title for Chicago journal article" do
    hash = Citation.parse('Wilcox, Rhonda V. 1991. Shifting roles and synthetic women in Star trek: The next generation. Studies in Popular Culture 13 (2): 53-65.')
    hash[:title].should == 'Shifting roles and synthetic women in Star trek: The next generation'
  end

  it "parses title for AMA journal article" do
    pending "Fails"
    hash = Citation.parse("Wilcox RV. Shifting roles and synthetic women in Star trek: the next generation. Stud Pop Culture. 1991;13:53-65.")
    hash[:title].should == 'Shifting roles and synthetic women in Star trek: The next generation'
  end

end
