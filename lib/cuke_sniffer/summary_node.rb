require 'roxml'
module CukeSniffer

  # Author::    Robert Cochran  (mailto:cochrarj@miamioh.edu)
  # Copyright:: Copyright (C) 2013 Robert Cochran
  # License::   Distributes under the MIT License
  # Single Summary Node object used for passing around results data and serializing out to xml
  # Mixins: ROXML
  class SummaryNode
    include ROXML
    xml_accessor :score
    xml_accessor :count
    xml_accessor :average
    xml_accessor :good
    xml_accessor :bad
    xml_accessor :threshold
  end # :nodoc:

end