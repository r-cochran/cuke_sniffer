#../features/step_definitions/dead_step_sorter_steps/complex_calculator_steps.rb
Then /^the result is "([^"]*)"$/ do |result|
  result.to_i.should == @first_number + @second_number
end
#../features/step_definitions/dead_step_sorter_steps/nested_steps/nested_steps.rb
Given /^I am a nested step$/ do
  puts "i have no functionality"
end
