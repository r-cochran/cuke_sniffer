AfterConfiguration do
  puts "I got into the after configuration hook"
  @@target_url = ENV['target_url']
end