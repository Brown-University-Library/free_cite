# encoding: UTF-8

module FreeCite

  module Preprocessor

    MARKER_TYPES = {
      :SQUARE       => '\\[.+?\\]',
      :PAREN        => '\\(.+?\\)',
      :NAKEDNUM     => '\\d+',
      :NAKEDNUMDOT  => '\\d+\\.',
    }

    CLEANUP_RULES_FILE = "#{File.dirname(__FILE__)}/../../config/citation_cleanup_rules.yml"

    def cleanup_rules
      return @rules if @rules

      raw = YAML.load_file CLEANUP_RULES_FILE
      @rules = raw['order'].map do |rule_name|
        re = Regexp.new(raw['rules'][rule_name]['regex'], raw['rules'][rule_name]['ignore_case'])
        repl = raw['rules'][rule_name]['replacement_str'] || ''
        { re: re, repl: repl }
      end
    end

    ##
    # Removes lines that appear to be junk from the citation text,
    # and applies cleanup regexes from the configuration file.
    ##
    def normalize_cite_text(cite_text)
      cite_text.split(/\n/).reject do |line|
        line.blank? || line =~ /^[\s\d]*$/
      end.map do |line|
        normalize_citation(line)
      end.join("\n")
    end

    def normalize_citation(cite)
      cite = cite.dup

      cleanup_rules.each do |rule|
        cite.gsub!(rule[:re], rule[:repl])
      end

      cite
    end

    ##
    # Controls the process by which citations are segmented,
    # based on the result of trying to guess the type of
    # citation marker used in the reference section.  Returns
    # a reference to a list of citation objects.
    ##
    def segment_citations(cite_text)
      marker_type = guess_marker_type(cite_text)
      unless marker_type == 'UNKNOWN'
        citations = split_unmarked_citations(cite_text)
      else
        citations = split_citations_by_marker(cite_text, marker_type)
      end
      return citations
    end

    ##
    # Segments citations that have explicit markers in the
    # reference section.  Whenever a new line starts with an
    # expression that matches what we'd expect of a marker,
    # a new citation is started.  Returns a reference to a
    # list of citation objects.
    ##
    def split_citations_by_marker(cite_text, marker_type=nil)
      citations = []
      current_citation = Citation.new
      current_citation_string = nil

      cite_text.split(/\n/).each {|line|
        if line =~ /^\s*(#{MARKER_TYPES{marker_type}})\s*(.*)$/
          marker, cite_string = $1, $2
          if current_citation_string
            current_citation.citation_string = current_citation_string
            citations << current_citation
            current_citation_string = nil
          end
          current_citation = Citation.new
          current_citation.marker_type = marker_type
          current_citation.marker = marker
          current_citation_string = cite_string
        else
          if current_citation_string =~ /\s\-$/
            current_citation_string.sub(/\-$/, '')
            current_citation_string << line
          else
            current_citation_string << " " << line
          end
        end
      }

      if current_citation && current_citation_string
        current_citation.string = current_citation_string
        citations << current_citation
      end
      citations
    end

  end
end
