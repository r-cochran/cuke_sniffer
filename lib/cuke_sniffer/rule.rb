require 'roxml'
module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # Single Rule object used for passing around rule data and serializing out to xml
  # Mixins: ROXML
  class Rule
    include ROXML
    xml_accessor :enabled
    xml_accessor :phrase
    xml_accessor :score
    xml_accessor :conditions, :as => {:key => "name", :value => "value"}, :in => "conditions", :from => "condition"
    xml_accessor :targets, :in => "targets"
    xml_accessor :reason

    def initialize
      @enabled = false
      @phrase = ""
      @score = 0
      @conditions = {}
      @targets = []
      @reason = ""
    end
  end

end