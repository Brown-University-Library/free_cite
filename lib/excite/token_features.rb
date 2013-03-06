# encoding: UTF-8

module Excite

  module TokenFeatures

    module DictFlags
      PUBLISHER_NAME = 32
      PLACE_NAME = 16
      MONTH_NAME = 8
      LAST_NAME = 4
      FIRST_NAME = 1
    end

    def TokenFeatures.read_dict_files(dir_name)
      dict = {}
      [
        ['first-names',DictFlags::FIRST_NAME],
        ['surnames',DictFlags::LAST_NAME],
        ['months',DictFlags::MONTH_NAME],
        ['places',DictFlags::PLACE_NAME],
        ['publishers',DictFlags::PUBLISHER_NAME],
      ].each do |file_name, flag|
        filename = File.join(dir_name, file_name)
        f = File.open(filename, 'r')

        while l = f.gets
          l.strip!
          if !l.match(/^\#/)
            dict[l] ||= 0
            unless dict[l] & flag > 0
              dict[l] += flag
            end
          end
        end

        f.close
      end
      dict
    end

    DIR = File.dirname(__FILE__)
    DICT = TokenFeatures.read_dict_files("#{DIR}/resources/dicts")

    private_class_method :read_dict_files

    def clear
      @possible_editor = nil
      @possible_chapter = nil
      @dict_status = nil
      @is_proceeding = nil
    end

    def last_char(toks, idx, author_names=nil)
      case toks[idx].raw[-1,1]
        when /[a-z]/
          'a'
        when /[A-Z]/
          'A'
        when /[0-9]/
          0
        else
          toks[idx].raw[-1,1]
      end
    end

    def first_1_char(toks, idx, author_names=nil); toks[idx].raw[0,1]; end
    def first_2_chars(toks, idx, author_names=nil); toks[idx].raw[0,2]; end
    def first_3_chars(toks, idx, author_names=nil); toks[idx].raw[0,3]; end
    def first_4_chars(toks, idx, author_names=nil); toks[idx].raw[0,4]; end
    def first_5_chars(toks, idx, author_names=nil); toks[idx].raw[0,5]; end

    def last_1_char(toks, idx, author_names=nil); toks[idx].raw[-1,1]; end
    def last_2_chars(toks, idx, author_names=nil); toks[idx].raw[-2,2] || toks[idx].raw; end
    def last_3_chars(toks, idx, author_names=nil); toks[idx].raw[-3,3] || toks[idx].raw; end
    def last_4_chars(toks, idx, author_names=nil); toks[idx].raw[-4,4] || toks[idx].raw; end

    def toklcnp(toks, idx, author_names=nil); toks[idx].lcnp; end

    def capitalization(toks, idx, author_names=nil)
      case toks[idx].np
        when "EMPTY"
          "others"
        when /^[[:upper:]]$/
          "singleCap"
        when /^[[:upper:]][[:lower:]]+/
          "InitCap"
        when /^[[:upper:]]+$/
          "AllCap"
        else
          "others"
      end
    end

    def numbers(toks, idx, author_names=nil)
      (toks[idx].raw           =~ /[0-9]\-[0-9]/)          ? "possiblePage" :
        (toks[idx].raw         =~ /^\D*(19|20)[0-9][0-9]\D*$/)   ? "year"         :
        (toks[idx].np       =~ /^(19|20)[0-9][0-9]$/)   ? "year"         :
        (toks[idx].np       =~ /^[0-9]$/)               ? "1dig"         :
        (toks[idx].np       =~ /^[0-9][0-9]$/)          ? "2dig"         :
        (toks[idx].np       =~ /^[0-9][0-9][0-9]$/)     ? "3dig"         :
        (toks[idx].np       =~ /^[0-9]+$/)              ? "4+dig"        :
        (toks[idx].np       =~ /^[0-9]+(th|st|nd|rd)$/) ? "ordinal"      :
        (toks[idx].np       =~ /[0-9]/)                 ? "hasDig"       : "nonNum"
    end

    # ignores idx
    def possible_editor(toks, idx=nil, author_names=nil)
      if !@possible_editor.nil?
        @possible_editor
      else
        @possible_editor =
          (toks.any? { |t|  %w(ed editor editors eds edited).include?(t.lcnp) } ?
            "possibleEditors" : "noEditors")
      end
    end

    # if there is possible editor entry and "IN" preceeded by punctuation
    # this citation may be a book chapter
    #
    # ignores idx
    def possible_chapter(toks, idx=nil, author_names=nil)
      if !@possible_chapter.nil?
        @possible_chapter
      else
        has_editor = possible_editor(toks) == 'possibleEditors'
        has_chapter = toks.each_with_index.any? do |t, i|
          if i > 0 && i < (toks.length-1) && t.lcnp == 'in'
            prev_is_separator = ['pp','ppr','ppc','pps'].include?(toks[i-1].part_of_speech)
            next_is_separator = ['ppl','ppc','pps'].include?(toks[i+1].part_of_speech)
            prev_is_separator && (has_editor || next_is_separator)
          end
        end
        has_chapter ? "possibleChapter" : "noChapter"
      end
    end

    # ignores idx
    def is_proceeding(toks, idx=nil, author_names=nil)
      if !@is_proceeding.nil?
        @is_proceeding
      else
        @is_proceeding =
          (toks.any? { |t|
            %w( proc proceeding proceedings ).include?(t.lcnp.strip)
          } ? 'isProc' : 'noProc')
      end
    end

    # TODO remove duplication with possible_chapter
    def is_in(toks, idx, author_names=nil)
      is_in = if idx > 0 && idx < (toks.length-1) && toks[idx].lcnp == 'in'
        prev_is_separator = ['pp','ppr','ppc','pps'].include?(toks[idx-1].part_of_speech)
        next_is_separator = ['ppl','ppc','pps'].include?(toks[idx+1].part_of_speech)
        prev_is_separator && (next_is_separator || toks[idx+1].np =~ /^[A-Z]/)
      end
      is_in ? "inBook" : "notInBook"
    end

    def location(toks, idx, author_names=nil)
      r = ((idx.to_f / toks.length) * 10).round
    end

    def punct(toks, idx, author_names=nil)
      (toks[idx].raw =~ /\-.*\-/)              ? "multiHyphen" :
      (toks[idx].raw =~ /[[:alpha:]].*\-$/)    ? "truncated"   :
      (toks[idx].raw =~ /[[:alpha:]].*\.$/)    ? "abbrev"      :
      (toks[idx].np != toks[idx].raw)          ? "hasPunct"    : "others"
    end

    def possible_volume(toks, idx, author_names=nil)
      if possible_vol_with_str(toks, idx)
        'volume'
      elsif possible_vol_with_str(toks, idx-1) && possible_issue_with_str(toks, idx)
        'issue'
      elsif possible_vol_with_str(toks, idx-2) && possible_issue_with_str(toks, idx-1) && possible_issue_with_str(toks, idx)
        'issue'
      elsif possible_vol_with_parens(toks, idx)
        'volume'
      elsif (1..3).any? { |i| possible_vol_with_parens(toks, idx-i) }
        'issue'
      elsif possible_vol_with_colon(toks, idx)
        'volume'
      else
        'noVolume'
      end
    end

    # TODO this method is weirdly named b/c of alphabetical ordering hack: remove that
    def a_is_in_dict(toks, idx, author_names=nil)
      dict_status(toks, idx)
    end

    def publisherName(toks, idx, author_names=nil)
      (dict_status(toks, idx) & DictFlags::PUBLISHER_NAME) > 0 ? 'publisherName' : 'noPublisherName'
    end

    def placeName(toks, idx, author_names=nil)
      (dict_status(toks, idx) & DictFlags::PLACE_NAME) > 0 ? 'placeName' : 'noPlaceName'
    end

    def monthName(toks, idx, author_names=nil)
      (dict_status(toks, idx) & DictFlags::MONTH_NAME) > 0 ? 'monthName' : 'noMonthName'
    end

    def lastName(toks, idx, author_names=nil)
      return 'lastName' if author_names && author_names.last == toks[idx].lcnp
      (dict_status(toks, idx) & DictFlags::LAST_NAME) > 0 ? 'lastName' : 'noLastName'
    end

    def firstName(toks, idx, author_names=nil)
      return 'firstName' if author_names && author_names.first == toks[idx].lcnp
      (dict_status(toks, idx) & DictFlags::FIRST_NAME) > 0 ? 'firstName' : 'noFirstName'
    end

    def dict_status(toks, idx)
      @dict_status ||= [nil]*toks.length
      @dict_status[idx] ||= (DICT[toks[idx].lcnp] || 0)
    end

    NODE_TYPES_BY_NAME = {
      'div'=>'div',
      'p'=>'p',
      'ul'=>'div', # lump with div - higher-level structure
      'li'=>'li',
      'tr'=>'div', # lump with div - higher-level structure
      'td'=>'td',
      'span'=>'span',
      'font'=>'span',
      'em'=>'em',
      'i'=>'em',
      'strong'=>'strong',
      'b'=>'strong',
      'u'=>'u',
      'h1'=>'h',
      'h2'=>'h',
      'h3'=>'h',
      'h4'=>'h',
      'h5'=>'h',
      'h6'=>'h',
      'a'=>'a',
      '#document-fragment'=>'unknown' # the actual tag wasn't captured in the fragment we're parsing
    }

    def tag_name(toks, idx, author_names=nil)
      name = toks[idx].node.parent.name # node is always a text node; the informative one is the parent
      NODE_TYPES_BY_NAME[name.downcase] || 'other'
    end

    def location_in_node(toks, idx, author_names=nil)
      ((toks[idx].idx_in_node.to_f / toks[idx].node_token_count) * 10).round
    end

    def part_of_speech(toks, idx, author_names=nil)
      toks[idx].part_of_speech
    end

  private

    def possible_issue_with_str(toks, idx)
      return unless toks[idx]

      possible_issue_str(toks, idx) ||
        (possible_issue_str(toks, idx-1) && toks[idx].raw =~ /^\d+$/)
    end

    def possible_issue_str(toks, idx)
      if toks[idx]
        if toks[idx].raw =~ /^(no)|(issue)?\.?\d+.?$/i
          return true
        elsif toks[idx+1]
          return ['no','issue'].include?(toks[idx].lcnp) && toks[idx+1].raw =~ /^\d+$/
        end
      end
    end

    def possible_vol_with_str(toks, idx)
      return unless toks[idx]

      possible_vol_str(toks, idx) ||
        (possible_vol_str(toks, idx-1) && (toks[idx].raw =~ /^\d+$/ || toks[idx].raw == ',')) ||
        (possible_vol_str(toks, idx-2) && toks[idx-1].raw =~ /^\d+$/ && toks[idx].raw == ',')
    end

    def possible_vol_str(toks, idx)
      if toks[idx]
        if toks[idx].raw =~ /^vol(ume)?\.?\d+.?$/i
          return true
        elsif toks[idx+1]
          return ['vol','volume'].include?(toks[idx].lcnp) && toks[idx+1].raw =~ /^\d+$/
        end
      end
    end

    def possible_vol_with_parens(toks, idx)
      if toks[idx] && toks[idx+3]
        toks[idx].raw =~ /^\d+$/ && toks[idx+1].raw == '(' && toks[idx+2].raw =~ /^\d+$/ && toks[idx+3].raw == ')'
      end
    end

    def possible_vol_with_colon(toks, idx)
      if toks[idx] && toks[idx+1]
        # case of <year>: something is common so make sure we exclude it
        if toks[idx].np =~ /^\d{1,3}$/ && toks[idx+1].raw =~ /^:/
          # at this point it's likely a volume, but exclude it if it's not followed by an apparent page or issue
          toks[idx+1].np =~ /^\d+$/ || (toks[idx+1].raw == ':' && toks[idx+2] && toks[idx+2].np =~ /^\d+/)
        end
      end
    end

  end

end
