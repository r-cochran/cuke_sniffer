Given /^the first number is 1$/ do
  steps "Given the first number is \"1\""
end

When /^the second number is 1$/ do
  @second_number = 1
end

When /^the calculator adds$/ do
  @result = @first_number + @second_number
end

Then /^the result is 2$/ do
  @result.should == 2
end
