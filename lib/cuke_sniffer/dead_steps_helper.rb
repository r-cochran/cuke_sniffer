module CukeSniffer
  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # Mixins: CukeSniffer::Constants
  class DeadStepsHelper
    include CukeSniffer::Constants

    def self.build_dead_steps_hash(step_definitions)
      dead_steps_hash = gather_all_dead_steps_by_file(step_definitions)
      sort_dead_steps_in_file!(dead_steps_hash)
      dead_steps_hash[:total] = count_dead_steps(dead_steps_hash)
      dead_steps_hash
    end

    def self.gather_all_dead_steps_by_file(step_definitions)
      dead_steps_hash = {}
      step_definitions.each do |step_definition|
        location_match = step_definition.location.match(/(?<file>.*).rb:(?<line>\d+)/)
        file_name = location_match[:file]
        regex = format_step_definition_regex(step_definition.regex)
        if step_definition.calls.empty?
          dead_steps_hash[file_name] ||= []
          dead_steps_hash[file_name] << "#{location_match[:line]}: /#{regex}/"
        end
      end
      dead_steps_hash
    end

    def self.format_step_definition_regex(regex)
      regex.to_s.match(/\(\?\-mix\:(?<regex>.*)\)/)[:regex]
    end

    def self.sort_dead_steps_in_file!(dead_steps_hash)
      dead_steps_hash.each_key do |file|
        dead_steps_hash[file].sort_by! { |row| row[/^\d+/].to_i }
      end
    end

    def self.count_dead_steps(dead_steps_hash)
      count = 0
      dead_steps_hash.each_value do |dead_steps_in_file_list|
        count += dead_steps_in_file_list.size
      end
      count
    end
  end
end