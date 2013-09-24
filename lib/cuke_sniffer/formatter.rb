require 'erb'

module CukeSniffer
  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # Mixins: CukeSniffer::Constants
  # Static class used to generate output for the CukeSniffer::CLI object.
  class Formatter
    include CukeSniffer::Constants

    # Prints out a summary of the results and the list of improvements to be made
    def self.output_console(cuke_sniffer)
      summary = cuke_sniffer.summary
      output = "Suite Summary" +
                "  Total Score: #{summary[:total_score]}\n" +
                get_output_summary_nodes(cuke_sniffer) +
                console_improvement_list(summary[:improvement_list])

      puts output
    end

    # Returns a string of formatted output for all the object sections of summary
    def self.get_output_summary_nodes(cuke_sniffer)
      output = ""
      [:features, :scenarios, :step_definitions, :hooks].each do |summary_section|
        output += console_summary(summary_section.to_s.gsub("_", " ").capitalize, cuke_sniffer.summary[summary_section])
      end
      output
    end

    # Formats the section data for a summary object
    def self.console_summary(name, summary)
      "  #{name}\n" +
      "    Min: #{summary[:min]} (#{summary[:min_file]})\n" +
      "    Max: #{summary[:max]} (#{summary[:max_file]})\n" +
      "    Average: #{summary[:average]}\n"
    end

    # Formats the improvement list data for summary
    def self.console_improvement_list(improvement_list)
      output = "  Improvements to make:\n"
      improvement_list.each do |improvement, count|
        output << "    (#{count}) #{improvement}\n"
      end
      output
    end

    # Creates a html file with the collected project details
    # file_name defaults to "cuke_sniffer_results.html" unless specified
    # Second parameter used for passing into the markup.
    #  cuke_sniffer.output_html
    # Or
    #  cuke_sniffer.output_html("results01-01-0001.html")
    def self.output_html(cuke_sniffer, file_name = DEFAULT_OUTPUT_FILE_NAME, template_name = "standard_template")
      cuke_sniffer = sort_cuke_sniffer_lists(cuke_sniffer)
      output = ERB.new(extract_markup("#{template_name}.html.erb")).result(binding)
      File.open(format_html_file_name(file_name), 'w') do |f| f.write(output) end
    end

    # Returns an ERB page built up for the passed file name
    def self.build_page(cuke_sniffer, erb_file)
      ERB.new(extract_markup(erb_file)).result(binding)
    end

    # Assigns an html extension if one is not provided for the passed file name
    def self.format_html_file_name(file_name)
      if file_name =~ /\.html$/
        file_name
      else
        file_name + ".html"
      end
    end

    # Creates a html file with minimum information: Summary, Rules, Improvement List.
    # file_name defaults to "cuke_sniffer_results.html" unless specified
    # Second parameter used for passing into the markup.
    #  cuke_sniffer.output_min_html
    # Or
    #  cuke_sniffer.output_min_html("results01-01-0001.html")
    def self.output_min_html(cuke_sniffer, file_name = DEFAULT_OUTPUT_FILE_NAME)
      output_html(cuke_sniffer, file_name, "min_template")
    end

    # Returns the Rules erb page that utilizes sub page sections of enabled and disabled rules
    def self.rules_template(cuke_sniffer)
      ERB.new(extract_markup("rules.html.erb")).result(binding)
    end

    # Creates a xml file with the collected project details
    # file_name defaults to "cuke_sniffer.xml" unless specified
    #  cuke_sniffer.output_xml
    # Or
    #  cuke_sniffer.output_xml("cuke_sniffer01-01-0001.xml")
    def self.output_xml(cuke_sniffer, file_name = DEFAULT_OUTPUT_FILE_NAME)
      file_name = file_name + ".xml" unless file_name =~ /\.xml$/

      doc = Nokogiri::XML::Document.new
      doc.root = cuke_sniffer.to_xml
      open(file_name, "w") do |file|
        file << doc.serialize
      end
    end

    # Sorts all of the lists on a cuke_sniffer object to be in descending order for each objects score.
    def self.sort_cuke_sniffer_lists(cuke_sniffer)
      cuke_sniffer.features = cuke_sniffer.features.sort_by { |feature| feature.total_score }.reverse
      cuke_sniffer.step_definitions = cuke_sniffer.step_definitions.sort_by { |step_definition| step_definition.score }.reverse
      cuke_sniffer.hooks = cuke_sniffer.hooks.sort_by { |hook| hook.score }.reverse
      cuke_sniffer.rules = cuke_sniffer.rules.sort_by { |rule| rule.score }.reverse
      cuke_sniffer
    end

    # Returns the markup for a desired erb file.
    def self.extract_markup(template_name = "markup.html.erb", markup_source = MARKUP_SOURCE)
      markup_location = "#{markup_source}/#{template_name}"
      markup = ""
      File.open(markup_location).lines.each do |line|
        markup << line
      end
      markup
    end

  end
end