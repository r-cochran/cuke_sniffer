Given /^the first number is "([^"]*)"$/ do |first_number|
  @first_number = first_number.to_i
end

When /^the second number is "([^"]*)"$/ do |second_number|
  @second_number = second_number.to_i
end

Then /^the result is "([^"]*)"$/ do |result|
  result.to_i.should == @first_number + @second_number
end

Then /^tacoasdfasdfasdasdasdfasasdfasdfasdfaadsfasdfadsdfafda$/ do |result|
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
  #result.to_i.should == @first_number + @second_number
end

Then /^tac$/ do |result|
  result.to_i.should == @first_number + @second_number
end