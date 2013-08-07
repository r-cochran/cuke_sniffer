require 'erb'
require 'pdfkit'

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
      feature_results = cuke_sniffer.summary[:features]
      scenario_results = cuke_sniffer.summary[:scenarios]
      step_definition_results = cuke_sniffer.summary[:step_definitions]
      hooks_results = cuke_sniffer.summary[:hooks]
      output = "Suite Summary
  Total Score: #{cuke_sniffer.summary[:total_score]}
    Features
      Min: #{feature_results[:min]} (#{feature_results[:min_file]})
      Max: #{feature_results[:max]} (#{feature_results[:max_file]})
      Average: #{feature_results[:average]}
    Scenarios
      Min: #{scenario_results[:min]} (#{scenario_results[:min_file]})
      Max: #{scenario_results[:max]} (#{scenario_results[:max_file]})
      Average: #{scenario_results[:average]}
    Step Definitions
      Min: #{step_definition_results[:min]} (#{step_definition_results[:min_file]})
      Max: #{step_definition_results[:max]} (#{step_definition_results[:max_file]})
      Average: #{step_definition_results[:average]}
    Hooks
      Min: #{hooks_results[:min]} (#{hooks_results[:min_file]})
      Max: #{hooks_results[:max]} (#{hooks_results[:max_file]})
      Average: #{hooks_results[:average]}
  Improvements to make:"

      cuke_sniffer.summary[:improvement_list].each_key { |improvement| output << "\n    (#{summary[:improvement_list][improvement]})#{improvement}" }
      puts output
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

    # Creates a pdf file with the collected project details
    # file_name defaults to cuke_sniffer_results.pdf unless specified.
    # Currently the pdf report is exactly the same as the html report with all
    # divs expanded.
    def self.output_pdf(cuke_sniffer, file_name = DEFAULT_OUTPUT_FILE_NAME)
      output_html(cuke_sniffer, file_name, "pdf_report.html.erb")
      create_pdf_from_html(file_name)
    end

    def self.create_pdf_from_html(file_name)
      temp_html_file = File.open(file_name + ".html")
      pdfkit = PDFKit.new(temp_html_file, :page_size => 'A3')
      pdfkit.to_file(file_name)
      File.delete(temp_html_file)
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