# Academia FreeCite

Stripped-down version of [FreeCite](http://freecite.library.brown.edu/) which provides a Ruby API for citation parsing.

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
