# useragent-parser
bundle install
bundle exec ruby parse-uas.rb <csv>

# csv format
# generated from sumologic using '_source = "HAProxy Logs" | extract "\{(?<agent>[^\"]+?)\}"  | count_frequent agent'
<uas>, #reqs
