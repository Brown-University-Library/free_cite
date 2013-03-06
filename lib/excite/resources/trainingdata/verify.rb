# encoding: UTF-8
#
# Script to assist in verifying tagged references

f = ARGV[0]

cleaned = IO.readlines(f).map(&:strip)

tags = []
tag_contents = {}

annotation_tags = %w{ author title date booktitle journal volume pages editor workid link publisher location institution bullet tech note }.map { |t| "<#{t}>" }

cleaned.each_with_index do |line, index|
  open_tags = line.scan(/<\s*\w+\s*>/).map(&:downcase)
  for tag in open_tags
    i = line.downcase.index(tag)
    j = line.downcase.index(tag.sub('<','</'))
    if tag != "<br>" && (j.nil? || j <= i)
      puts "Missing close tag for #{tag} on line #{index+1}: #{line}"
    end
  end

  close_tags = line.scan(/<\/\s*\w+\s*>/).map(&:downcase)
  for tag in close_tags
    i = line.downcase.index(tag)
    j = line.downcase.index(tag.sub(/<\/\s*/, ''))
    if j.nil? || j >= i
      puts "Missing open tag for #{tag} on line #{index+1}: #{line}"
    end
  end

  tags += open_tags

  toks = line.split(/(\s+)|(?=<)|(?<=>)/)

  start_tag = nil
  tag_content = ''

  for tok in toks
    if annotation_tags.include?(tok)
      if !start_tag.nil?
        puts "Started #{tok} within #{start_tag} on line #{index+1}: #{line}"
        start_tag = nil
      else
        start_tag = tok
      end
    elsif annotation_tags.include?(tok.sub(/<\/\s*/, '<'))
      if start_tag.nil?
        puts "End tag #{tok} without a corresponding start tag on line #{index+1}: #{line}"
      elsif start_tag != tok.sub(/<\/s*/, '<')
        puts "End tag #{tok} doesn't match start tag #{start_tag} on line #{index+1}: #{line}"
        start_tag = nil
      else
        tag_contents[start_tag] ||= []
        tag_contents[start_tag] << tag_content.strip

        tag_content = ''
        start_tag = nil
      end
    elsif start_tag.nil?
      puts "Token '#{tok}' is not tagged in line #{index+1}: #{line}" unless tok.strip.empty?
    else
      tag_content += tok
    end
  end

  for tag in annotation_tags
    if open_tags.count(tag) > 1
      puts "(Might be ok but...) More than one #{tag} in line #{index+1}: #{line}"
    end
  end

  for tag in open_tags
    if open_tags.count(tag) != close_tags.count(tag.sub('<','</'))
      puts "Unequal numbers of open and close tags for #{tag} in line #{index+1}: #{line}" unless tag.match(/<\/?br>/)
    end
  end

  if !open_tags.include?("<title>")
    puts "Missing title on line #{index+1}: #{line}"
  end
end

tag_counts = tags.inject({}) do |counts, tag|
  counts[tag] ||= 0
  counts[tag] += 1
  counts
end

puts "\n\nAnnotation tags used: #{tag_counts.select { |t,c| annotation_tags.include?(t) } }"
puts "Other tags: #{tag_counts.reject { |t,c| annotation_tags.include?(t) }}\n\n\n"

tag_contents.each do |tag, contents|
  puts "#{tag}s:"
  contents.each { |c| puts "\t\t#{c}" }
end
