# encoding: UTF-8

describe Citation do

  it "handles nil" do
    Citation.parse(nil).should be_nil
  end

  it "handles empty string" do
    Citation.parse("").should be_nil
  end

  it "handles string that used to break model" do
    Citation.parse("[if gte mso 10]>\r\n<style>\r\n /* Style Definitions */\r\n table.MsoNormalTable\r\n\t{mso-style-name:\"Table Normal\";\r\n\tmso-tstyle-rowband-size:0;\r\n\tmso-tstyle-colband-size:0;\r\n\tmso-style-noshow:yes;\r\n\tmso-style-priority:99;\r\n\tmso-style-parent:\"\";\r\n\tmso-padding-alt:0in 5.4pt 0in 5.4pt;\r\n\tmso-para-margin:0in;\r\n\tmso-para-margin-bottom:.0001pt;\r\n\tmso-pagination:widow-orphan;\r\n\tfont-size:10.0pt;\r\n\tfont-family:\"Times New Roman\",\"serif\";}\r\n</style>\r\n<![endif]").has_year?.should be_false
  end

  it "handles non-ASCII unicode characters" do
    cite = Citation.parse("Okuda, Michael, and Denise Okuda. 1993. Star trek chronology » The history of the future りがと. New York: Pocket Books.")
    title_should_be(cite, "Star trek chronology » The history of the future")
  end

  it "has_authors? returns false for non-citation string" do
    Citation.parse("Recently while contemplating hosting options for my startup I decided to take a look at Heroku.").has_authors?.should be_false
  end

  it "parses title for APA journal article" do
    cite = Citation.parse("Devine, P. G., & Sherman, S. J. (1992). Intuitive versus rational judgment and the role of stereotyping in the human condition: Kirk or Spock? Psychological Inquiry, 3(2), 153-159. doi:10.1207/s15327965pli0302_13")
    title_should_be(cite, "Intuitive versus rational judgment and the role of stereotyping in the human condition: Kirk or Spock")
  end

  it "parses title for Turabian journal article" do
    cite = Citation.parse("Wilcox, Rhonda V. 1991. Shifting roles and synthetic women in Star trek: The next generation. Studies in Popular Culture 13 (June): 53-65.")
    title_should_be(cite, 'Shifting roles and synthetic women in Star trek: The next generation')
  end

  it "parses title for Turabian book" do
    cite = Citation.parse("Okuda, Michael, and Denise Okuda. 1993. Star trek chronology: The history of the future. New York: Pocket Books.")
    title_should_be(cite, "Star trek chronology: The history of the future")
  end

  it "parses title for MLA newspaper article" do
    cite = Citation.parse('Di Rado, Alicia. "Trekking through College: Classes Explore Modern Society Using the World of Star Trek." Los Angeles Times 15 Mar. 1995: A3+. Print.')
    title_should_be(cite, 'Trekking through College: Classes Explore Modern Society Using the World of Star Trek')
  end

  it "parses title for Chicago journal article" do
    cite = Citation.parse('Wilcox, Rhonda V. 1991. Shifting roles and synthetic women in Star trek: The next generation. Studies in Popular Culture 13 (2): 53-65.')
    title_should_be(cite, 'Shifting roles and synthetic women in Star trek: The next generation')
  end

  it "parses title for journal article with volume" do
    cite = Citation.parse("Watts, S. & Bagnoli, M. (2010). Oligopoly, Disclosure and Earnings Management. The Accounting Review, vol. 85 (4), 1191-1214.")
    title_should_be(cite, "Oligopoly, Disclosure and Earnings Management")
  end

  it "parses title for MLA journal article" do
    cite = Citation.parse('Hodges, F. M. "The Promised Planet: Alliances and Struggles of the Gerontocracy in American Television Science Fiction of the 1960s." Aging Male 6.3 (2003)')
    title_should_be(cite, "The Promised Planet: Alliances and Struggles of the Gerontocracy in American Television Science Fiction of the 1960s")
  end

  it "parses title for AMA journal article" do
    cite = Citation.parse("Wilcox RV. Shifting roles and synthetic women in Star trek: The next generation. Stud Pop Culture. 1991;13:53-65.")
    title_should_be(cite, 'Shifting roles and synthetic women in Star trek: The next generation')
  end

  it "parses quoted journal article title" do
    cite = Citation.parse('“Standing in Livestock’s ‘Long Shadow’: The Ethics of Eating Meat on a Small Planet,” Ethics & the Environment 16 (2011): 63-93. (pdf)')
    title_should_be(cite, 'Standing in Livestock’s ‘Long Shadow’: The Ethics of Eating Meat on a Small Planet')
  end

  it "parses citation prefixed by number" do
    cite = Citation.parse('1. “Mechanisms of network collapse in GeO2 glass: high-pressure neutron diffraction with isotope substitution as arbitrator of competing models ” Kamil Wezka ,Philip Salmon, Anita Ziedler, Dean Whittaker, James Drewitt, Stefan Klotz, Harry Fisher and D Marrocchelli, Journal of Physics: Condensed Matter 24 502101 (2012)')
    title_should_be(cite, 'Mechanisms of network collapse in GeO2 glass: high-pressure neutron diffraction with isotope substitution as arbitrator of competing models')
  end

  it "parses citation prefixed by number without space" do
    cite = Citation.parse("3.“ High pressure neutron diffraction study of GeO2 glass up to 17.5 GPa ” Philip Salmon, James Drewitt, Dean Whittaker, Anita Ziedler, Kamil Wezka, Craig Bull, Mathew Tucker, Martin Wilding, Malcon Guthrie and D Marrocchelli, Journal of Physics: Condensed Matter 24 415102 (2012)")
    title_should_be(cite, 'High pressure neutron diffraction study of GeO2 glass up to 17.5 GPa')
  end

  context "not yet working" do

    before do
      pending "would be nice to fix these"
    end

    it "parses citation with parenthetical comment" do
      cite = Citation.parse('The Ethics of Creativity: Beauty, Morality, and Nature in a Processive Cosmos (University of Pittsburgh Press 2005). (Awarded the Metaphysical Society of America’s 2007 John N. Findlay Book Prize.)')
      title_should_be(cite, 'The Ethics of Creativity: Beauty, Morality, and Nature in a Processive Cosmos')
    end

  end

  def title_should_be(cite, title)
    cite[:title].should == title
    cite.overall_probability.should be_within(0.5).of(0.5)
    cite.probabilities[:title].should be_within(0.5).of(0.5)
  end

end
