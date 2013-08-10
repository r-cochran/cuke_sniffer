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
      output = "Suite Summary" +
                "  Total Score: #{cuke_sniffer.summary[:total_score]}\n" +
                "#{console_summary("Features", cuke_sniffer.summary[:features])}\n" +
                "#{console_summary("Scenarios", cuke_sniffer.summary[:scenarios])}\n" +
                "#{console_summary("Step Definitions", cuke_sniffer.summary[:step_definitions])}\n" +
                "#{console_summary("Hooks", cuke_sniffer.summary[:hooks])}\n" +
                "  Improvements to make:\n"

      cuke_sniffer.summary[:improvement_list].each_key do |improvement|
        output << "\n    (#{cuke_sniffer.summary[:improvement_list][improvement]}) #{improvement}"
      end
      puts output
    end

    def self.console_summary(name, summary)
      "  #{name}\n" +
      "    Min: #{summary[:min]} (#{summary[:min_file]})\n" +
      "    Max: #{summary[:max]} (#{summary[:max_file]})\n" +
      "    Average: #{summary[:average]}\n"
    end

    # Creates a html file with the collected project details
    # file_name defaults to "cuke_sniffer_results.html" unless specified
    # Second parameter used for passing into the markup.
    #  cuke_sniffer.output_html
    # Or
    #  cuke_sniffer.output_html("results01-01-0001.html")
    def self.output_html(cuke_sniffer, file_name = DEFAULT_OUTPUT_FILE_NAME, template_name = "markup.html.erb")
      file_name = file_name + ".html" unless file_name =~ /\.html$/
      cuke_sniffer = sort_cuke_sniffer_lists(cuke_sniffer)

      enabled_rules = rules_template(cuke_sniffer, true, "Enabled Rules")
      disabled_rules = rules_template(cuke_sniffer, false, "Disabled Rules")

      markup_erb = ERB.new extract_markup(template_name)
      output = markup_erb.result(binding)

      File.open(file_name, 'w') do |f|
        f.write(output)
      end
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

    def self.convert_array_condition_into_list_of_strings(condition_list)
      result = []
      while condition_list.size > 0
        five_words = condition_list.slice!(0, 5)
        result << five_words.join(", ")
      end
      result
    end

    def self.rules_template(cuke_sniffer, state, heading)
      markup_rules = ERB.new extract_markup("rules.html.erb")
      markup_rules.result(binding)
    end

    def self.sort_cuke_sniffer_lists(cuke_sniffer)
      cuke_sniffer.features = cuke_sniffer.features.sort_by { |feature| feature.total_score }.reverse
      cuke_sniffer.step_definitions = cuke_sniffer.step_definitions.sort_by { |step_definition| step_definition.score }.reverse
      cuke_sniffer.hooks = cuke_sniffer.hooks.sort_by { |hook| hook.score }.reverse
      cuke_sniffer.rules = cuke_sniffer.rules.sort_by { |rule| rule.score }.reverse
      cuke_sniffer
    end

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