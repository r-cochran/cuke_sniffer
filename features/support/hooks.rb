AfterConfiguration do
  puts "after configuration"
end

Before('@tag') do
  puts "before @tag ran"
end

Before('~@tag') do
  puts "before ~@tag ran"
end

After('@tag') do
  puts "after @tag ran"
end

After('~@tag,@tag2', '@tag3') do
  puts "after @tag ran"
end

at_exit do
  puts "closing down."
end
