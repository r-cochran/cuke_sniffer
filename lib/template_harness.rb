require 'erb'

class TemplateHarness

 def readFile
   content=""
   spec = Gem::Specification.find_by_name("cuke_sniffer")
   gem_root = spec.gem_dir
   File.open(gem_root + "/lib/output.rhtml", "r") do |infile|
     while (line = infile.gets)
       content+=line
     end
   end
   content
 end

 def initialize
  @template = ERB.new readFile
 end

  def print(features, steps, summary)
    output = @template.result(binding)
    File.open("output.html", 'w') do |f|
      f.write(output)
    end
  end
end