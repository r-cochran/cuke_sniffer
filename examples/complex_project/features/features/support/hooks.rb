Before('@OH') do
  puts "I am doing an OH account"
  @@state = "OH"
end

After('@OH') do
  puts "I finished doing an OH account"
end

Before('@KY') do
  begin
    @@state = "KY"
  rescue Exception => e
  end
end

Before('@NY') do
  begin
    @@state = "NY"
  rescue Exception => e
  end
end
