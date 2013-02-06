require 'free_cite/crfparser'

DIR = File.dirname(__FILE__)
ROOT_DIR = "#{DIR}/../.."
RESOURCES_DIR = "#{ROOT_DIR}/lib/free_cite/resources"
TAGGED_REFERENCES = "#{RESOURCES_DIR}/trainingdata/tagged_references.txt"
TAGGED_HTML_REFERENCES = "#{RESOURCES_DIR}/trainingdata/tagged_html_references.txt"
TRAINING_DATA = "#{DIR}/training_data.txt"
TESTING_DATA = "#{DIR}/testing_data.txt"
TRAINING_REFS = "#{DIR}/training_refs.txt"
TESTING_REFS = "#{DIR}/testing_refs.txt"
MODEL_FILE = "#{DIR}/model"
TEMPLATE_FILE = "#{RESOURCES_DIR}/parsCit.template"
HTML_TEMPLATE_FILE = "#{RESOURCES_DIR}/html.template"
OUTPUT_FILE = "#{DIR}/output.txt"
HTML_OUTPUT_FILE = "#{DIR}/html-output.txt"
ANALYSIS_FILE= "#{DIR}/analysis.csv"
HTML_ANALYSIS_FILE = "#{DIR}/html-analysis.csv"
REFS_PREFIX = "training_refs_"
DATA_PREFIX = "training_data_"
TAG = "model_test"

require "#{ROOT_DIR}/model/test/array_helpers"

class Array
  include ArrayHelpers
end

module FreeCite

  class ModelTest

    def analysis_file
      if @mode == :html
        HTML_ANALYSIS_FILE
      else
        ANALYSIS_FILE
      end
    end

    def output_file
      if @mode == :html
        HTML_OUTPUT_FILE
      else
        OUTPUT_FILE
      end
    end

    def template_file
      if @mode == :html
        HTML_TEMPLATE_FILE
      else
        TEMPLATE_FILE
      end
    end

    def tagged_references
      if @mode == :html
        TAGGED_HTML_REFERENCES
      else
        TAGGED_REFERENCES
      end
    end

    def initialize(mode = :string)
      @crf = CRFParser.new(mode)
      @mode = mode
    end

    def version
      @version ||=  `cd #{ROOT_DIR}; git show --pretty=oneline HEAD | head -1`.strip
    end

    def branch
      if @branch.nil?
        branch = `cd #{ROOT_DIR}; git branch`
        branch =~ /\*\s+(\S+)/
        @branch = $1
      end
      @branch
    end

    def aggregate_tags
      branches = `git branch`.gsub(/\*/, '').strip.split(/\s+/)
      branches.each {|branch|
        `git checkout #{branch}`
        tags = `git tag -l #{TAG}\*`.strip.split(/\s+/)
      }
    end

  #  def benchmark
  #    refs = []
  #    f = File.open(TRAINING_REFS, 'r')
  #    while line = f.gets
  #     refs << line.strip
  #    end
  #    # strip out tags
  #    refs.map! {|s| s.gsub(/<[^>]*>/, '')}
  #    # parse one string, since the lexicon is lazily evaluated
  #    Citation.create_from_string(refs.first)
  #    time = Benchmark.measure {
  #      refs.each {|ref| Citation.create_from_string(ref) }
  #    }
  #    return (time.real / refs.length.to_f)
  #  end

    def run_test(commit=false, commit_message="evaluating model", tag_name='', k=10)
      cross_validate(k)
      accuracy = analyze(k)
      #time = benchmark
      #`echo "Average time per parse:,#{time}\n" >> #{analysis_file}`

      if commit and tag_name.strip.blank?
        raise "You must supply a tag name if you want to commit and tag this test"
      end

      if commit
        str = "git add #{analysis_file} #{output_file}"
        puts "Adding test files to index \n#{str}"
        `#{str}`

        str = "git commit --message '#{commit_message}' #{analysis_file} #{output_file}"
        puts "Committing files to source control \n#{str}"
        `#{str}`

        str = "git tag #{TAG}_#{tag_name}_#{accuracy}"
        puts "Tagging: \n#{str}"
        `#{str}`
      end
    end

    def cleanup
      to_remove = [TRAINING_DATA, TESTING_DATA, TRAINING_REFS, TESTING_REFS, MODEL_FILE]
      `rm -f #{to_remove.join(" ")} #{DIR}/#{DATA_PREFIX}*txt #{DIR}/#{REFS_PREFIX}*txt`
    end

    def cross_validate(k=10)
      generate_data(k)
      # clear the output file
      f = File.open(output_file, 'w')
      f.close
      k.times {|i|
        puts "Performing #{i+1}th iteration of #{k}-fold cross validation"
        # generate training refs
        `rm #{TRAINING_DATA}; touch #{TRAINING_DATA};`
        k.times {|j|
          next if j == i
          `cat #{DIR}/#{DATA_PREFIX}#{j}.txt >> #{TRAINING_DATA}`
        }
        puts "Training model"
        train
        `cat #{DIR}/#{DATA_PREFIX}#{i}.txt > #{TESTING_DATA}`
        puts "Testing model"
        test
      }
    end

    # testpct: percentage of tagged references to hold out for testing
    def generate_data(k=10)
      testpct = k/100.0
      lines = []
      k.times { lines << [] }
      f = File.open(tagged_references, 'r')
      while line = f.gets
        lines[((rand * k) % k).floor] << line.strip
      end
      f.close

      lines.each_with_index {|ll, i|
        f = File.open("#{DIR}/#{REFS_PREFIX}#{i}.txt", 'w')
        f.write(ll.join("\n"))
        f.flush
        f.close
        @crf.write_training_file("#{DIR}/#{REFS_PREFIX}#{i}.txt",
                                "#{DIR}/#{DATA_PREFIX}#{i}.txt")
      }
    end

    def train
      @crf.train(TRAINING_REFS, MODEL_FILE, template_file, TRAINING_DATA)
    end

    def test
      str = "crf_test -m #{MODEL_FILE} #{TESTING_DATA} >> #{output_file}"
      puts str
      `#{str}`
    end

    def analyze(k)
      # get the size of the corpus
      corpus_size = `wc #{tagged_references}`.split.first

      # go through all training/testing data to get complete list of output tags
      labels = {}
      [TRAINING_DATA, TESTING_DATA].each {|fn|
        f = File.open(fn, 'r')
        while l = f.gets
          next if l.strip.blank?
          labels[l.strip.split.last] = true
        end
        f.close
      }
      labels = labels.keys.sort
      #puts "got labels:\n#{labels.join("\n")}"

      # reopen and go through the files again
      # for each reference, populate a confusion matrix hash
      references = []
      testf = File.open(output_file, 'r')
      ref = new_hash(labels)
      while testl = testf.gets
        if testl.strip.blank?
          references << ref
          ref = new_hash(labels)
          next
        end
        w = testl.strip.split
        te = w[-1]
        tr = w[-2]
        #puts "#{te} #{tr}"
        ref[tr][te] += 1
      end
      testf.close

      # print results to a file
      f = File.open(analysis_file, 'w')
      f.write "Results for model\n branch: #{branch}\n version: #{version}\n"
      f.write "Test run on:,#{Time.now}\n"
      f.write "K-fold x-validation:,#{k}\n"
      f.write "Corpus size:,#{corpus_size}\n\n"

      # aggregate results in total hash
      total = {}
      labels.each {|trl|
        labels.each {|tel|
            total[trl] ||= {}
            total[trl][tel] = references.map {|r| r[trl][tel]}.sum
        }
      }

      # print a confusion matrix
      f.write 'truth\test,'
      f.write labels.join(',')
      f.write "\n"
      # first, by counts
      labels.each {|trl|
        f.write "#{trl},"
        f.write( labels.map {|tel| total[trl][tel] }.join(',') )
        f.write "\n"
      }
      # then by percent
      labels.each {|trl|
        f.write "#{trl},"
        f.write labels.map{|tel| total[trl][tel]/total[trl].values.sum.to_f }.join(',')
        f.write "\n"
      }

      # precision and recal by label
      f.write "\n"
      f.write "Label,Precision,Recall,F-measure\n"
      labels.each {|trl|
        p = total[trl][trl].to_f / labels.map{|l| total[l][trl]}.sum
        r = total[trl][trl].to_f / total[trl].values.sum
        fs = (2*p*r)/(p+r)
        f.write "#{trl},#{p},#{r},#{fs}\n"
      }

      # get the average accuracy-per-reference
      perfect = 0
      avgs = references.map {|r|
        n = labels.map {|label| r[label][label] }.sum
        d = labels.map {|lab| r[lab].values.sum }.sum
        perfect += 1 if n == d
        n.to_f / d
      }
      f.write "\nAverage accuracy by reference:,#{avgs.mean}\n"
      f.write "STD of Average accuracy by reference:,#{avgs.stddev}\n"

      # number of perfectly parsed references
      f.write "Perfect parses:,#{perfect},#{perfect.to_f/references.length}\n"

      # Total accuracy
      n = labels.map {|lab| total[lab][lab]}.sum
      d = labels.map {|lab1| labels.map {|lab2| total[lab1][lab2]}.sum }.sum
      f.write "Accuracy:, #{n/d.to_f}\n"

      f.flush
      f.close

      return n/d.to_f
    end

    private
    def new_hash(labels)
      h = Hash.new
      labels.each {|lab1|
        h[lab1] = {}
        labels.each {|lab2|
          h[lab1][lab2] = 0
        }
      }
      h
    end
  end

end
