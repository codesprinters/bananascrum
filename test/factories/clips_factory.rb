Factory.sequence(:clip_file_name) { |n| "clip#{n}.txt" }

Factory.define(:clip) do |c|
  c.content_content_type "text/plain"
  c.content_file_name { Factory.next(:clip_file_name) }
  c.content_file_size 1.megabyte
end