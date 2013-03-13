# Excite

Provides a simple Ruby API for parsing citations from plain text strings or HTML.

## Usage

```ruby
  require 'excite'

  Excite.parse_string("Wilcox, Rhonda V. 1991. Shifting roles and synthetic women in Star trek: The next generation. Studies in Popular Culture 13 (June): 53-65.")

  Excite.parse_html("<span>Devine, PG, & Sherman, SJ</span><span>(1992)</span><strong>Intuitive versus rational judgment and the role of stereotyping in the human condition: Kirk or Spock?</strong><em>Psychological Inquiry</em><span>3(2), 153-159</span>")
```

## History and Credits

Derived from [FreeCite](http://freecite.library.brown.edu/), minus Rails and all UI elements. The most up-to-date fork of FreeCite of which I am aware is [rsinger's](https://github.com/rsinger/free_cite). FreeCite in turn is inspired by [ParsCit](http://aye.comp.nus.edu.sg/parsCit/).

The main changes are:
* No UI, just a gem;
* New model for parsing HTML;
* Tokenization and part-of-speech features from [EngTagger](https://github.com/yohasebe/engtagger).

Credit is due to the authors of all the linked projects, as well as Laura Durkay who marked up the HTML training data.

## Install required packages

### From source

    wget http://crfpp.googlecode.com/files/CRF%2B%2B-0.57.tar.gz
    tar xvzf CRF++-0.57.tar.gz
    cd CRF++-0.57
    ./configure 
    make
    sudo make install

### On Ubuntu

    sudo apt-add-repository 'deb http://cl.naist.jp/~eric-n/ubuntu-nlp oneiric all'
    sudo apt-get update
    sudo apt-get install libcrf++

### On OS X with Homebrew

    brew install crf++

