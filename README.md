## useragent-parser
```bash
bundle install
bundle exec ruby parse-uas.rb <csv>
```

## csv format
`generated from sumologic using '_source = "HAProxy Logs" | extract "\{(?<agent>[^\"]+?)\}"  | count_frequent agent'`
```csv
"agent","_approxcount"
"Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)","172699"
"Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)","143022"
"Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36","108007"
"Mozilla/5.0 (compatible; Baiduspider/2.0; +http://www.baidu.com/search/spider.html)","77706"
...
```
