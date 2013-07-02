Given /^Hello \"(.*)\"$/ do |name|
steps "And Hello #{name}"
end

And /^Hello John$/ do
end
