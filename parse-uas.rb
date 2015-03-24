#!/usr/bin/env ruby


require 'csv'
require 'active_support/all'
require 'byebug'
require 'gruff'
require 'pp'

det = CSV.open(ARGV[0]).to_a

osmap = [
  # more specific at top
  {:rexp => [/Macintosh/], :type => :desktop, :name => :MacOS, :version => [/Mac OS X\s*(?<version>[^);]*)(?:\)|;)/]},

  {:rexp => [[/CFNetwork/, /x86/]], :type => :desktop, :name => :MacOS},
  {:rexp => [/CFNetwork/], :type => :mobile, :name => :iOS},


  # windows phone is more specific than android
  {:rexp => [/windows phone/i], :type => :mobile, :name => :Windows, :version => [/Windows Phone OS (?<version>\d+\.?\d*)/, /Windows Phone (?<version>\S+)/]},
  {:rexp => [/windows/i, /WinNT/], :type => :desktop, :name => :Windows, :version => [/Windows NT (?<version>\d+\.?\d*)/, /Windows (?<version>\d+)/]},

  # android is more specific than linux
  {:rexp => [%r{android; tablet;}i], :type => :tablet, :name => :Android, :version => [%r{Android (?<version>\S+)}]},
  {:rexp => [%r{android}i], :type => :mobile, :name => :Android, :version => [%r{Android (?<version>\S+)}]},
  {:rexp => [/Ubuntu/], :type => :desktop, :name => :Linux, :os_name => :Ubuntu},
  {:rexp => [/linux/i], :type => :desktop, :name => :Linux},

  {:rexp => [/FreeBSD/], :type => :desktop, :name => :Linux, :os_name => :FreeBSD},
  {:rexp => [/OpenBSD/], :type => :desktop, :name => :Linux, :os_name => :OpenBSD},


  # iOS*
  {:rexp => [/iPad/i], :type => :tablet, :name => :iOS, :version => [/CPU OS (?<version>\S+)/]},
  {:rexp => [/iPhone|iPod/i], :type => :mobile, :name => :iOS, :version => [/CPU iPhone OS (?<version>\S+)/]},

  {:rexp => [/BB10/, /BlackBerry/], :type => :mobile, :name => :Blackberry},
  {:rexp => [/CrOS/], :type => :desktop, :name => :Chromium},
]

browsermap = [
  # more specific at top
  {:rexp => [%r{/bot}, %r{bot.htm}, %r{/robot}, %r{robot/}, %r{spider}, %r{Alexabot}, %r{ysearch/slurp},
             %r{tab=linkAnalyze}, %r{xovibot}], :os_condition => [lambda { |uas, os| os == :unknown }], :name => :Bot},
  {:rexp => [/Opera/], :name => :Opera, :version => [/Opera\/(?<version>\S+)/]},
  {:rexp => [/Chrome/], :name => :Chrome, :version => [/Chrome\/(?<version>\S+)/]},
  {:rexp => [/Firefox/], :name => :Firefox, :version => [/Firefox\/(?<version>\S+)/]},
  {:rexp => [/MSIE/], :name => :IE, :version => [/MSIE\s*(?<version>\d+)/], :full_version => [/MSIE\s*(?<version>\d+(?:\.\w+)*)\s*(?:;|-|\))/]},
  {:rexp => [%r{AppleWebKit/}], :os_condition => [lambda { |uas, os| os == :iOS }], :name => :Safari},
  {:rexp => [%r{AppleWebKit/}], :os_condition => [lambda { |uas, os| os == :Android }], :name => :Chrome},
  {:rexp => [%r{AppleWebKit/}], :os_condition => [lambda { |uas, os| os == :Blackberry }], :name => :Webkit},
  {:rexp => [[%r{Trident/},%r{rv:}]], :os_condition => [lambda { |uas, os| os == :Windows }], :name => :IE, :version => [/rv:(?<version>\d+)/]},
  {:rexp => [/Chro/], :name => :Chrome, :os_condition => [lambda { |uas, os| os == :Android || os == :Linux }]},
  {:rexp => [/Safari/], :name => :Safari, :version => [/Safari\/(?<version>\S+)/]},
]

agg  = {
  :by_os          => {}, # broken down by num_reqs per OS
  :by_os_type     => {}, # broken down by num_reqs per desktop (or mobile or tablet)
  :by_browsers    => {}, # broken down by #reqs per browser
  :by_ie_versions => {}, # usage by IE version
}
init = false

def recur_match(rexp, val)
  if rexp.is_a?(Array)
    rexp.all? { |rrexp| recur_match(rrexp, val) }
  else
    rexp.match(val)
  end
end

det.each do |v|
  next if v[1] =~ /_approxcount/
  next if v[0] =~ /SiteLockSpider/
  s = v[0]

  os              = :unknown
  os_version      = :unknown
  os_type         = :unknown
  browser         = :unknown
  browser_version = :unknown

  osmap.each do |entry|
    if entry[:rexp].detect { |rexp| recur_match(rexp, v[0]) }
      os = entry[:name] # entry[:os_name] ? entry[:os_name] : entry[:name]
      if entry[:version] && matched_rexp = (entry[:version].detect { |vrexp| vrexp.match(v[0]) })
        os_version = (matched_rexp.match(v[0]))[:version]
      end
      os_type = entry[:type]
      break
    end
  end

  browsermap.each do |entry|
    if entry[:os_condition]
      next unless entry[:os_condition].detect { |func| func.call(v[0], os) }
    end
    if entry[:rexp].detect { |rexp| recur_match(rexp, v[0]) }
      browser = entry[:name]
      if entry[:version] && matched_rexp = (entry[:version].detect { |vrexp| vrexp.match(v[0]) })
        browser_version = (matched_rexp.match(v[0]))[:version]
      end
      break
    end
  end
  # puts v if browser == :Chrome
  # puts v[0] if os == :iOS
  # if browser == :IE && browser_version == :unknown
  #   puts v[0]
  # end


  reqs                                  = Integer(v[1])
  agg[:by_os][os]                       = agg[:by_os][os] ? agg[:by_os][os] + reqs : reqs
  agg[:by_os_type][os_type]             = agg[:by_os_type][os_type] ? agg[:by_os_type][os_type] + reqs : reqs
  agg[:by_browsers][browser]            = agg[:by_browsers][browser] ? agg[:by_browsers][browser] + reqs : reqs
  agg[:by_ie_versions][browser_version] = agg[:by_ie_versions][browser_version] ? agg[:by_ie_versions][browser_version] + reqs : reqs if browser == :IE
end

pp JSON.parse(agg.to_json)

dir = Time.now.strftime("%H_%M_%d_%m_%y")
`/bin/rm -rf #{dir}; mkdir -p #{dir}`

agg.keys.each do |chart|
  g       = Gruff::Pie.new
  g.theme = Gruff::Themes::PASTEL
  agg[chart].each { |k, v| g.data(k, v) unless k == :unknown }
  g.write("#{dir}/#{chart}.png")
end