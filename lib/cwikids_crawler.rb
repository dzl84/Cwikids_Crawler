require_relative './http_helper'
require_relative './mail_helper'
require 'nokogiri'
require 'logging'

class Cwikids_Crawler

  HOST = "http://reg.cwikids.org"
  KNOWN_FILE = "/data/cwikids_activities.txt"

  # Crawl data from cwikids website
  def initialize
    @httpclient = HTTPHelper.new(HOST)
    @mailclient = MailHelper.new
    @new_activity = []
    @logger = Logging.logger(STDOUT)

    load_known_activities
  end

  def load_known_activities
    begin
      @known_activities = File.read(KNOWN_FILE).split("\n")
    rescue
      @known_activities = []
    end
  end

  # Save newly found activities to file
  def save_activities
    File.open(KNOWN_FILE, 'a') { |f|
      @new_activity.each{|node|
        f.puts("#{node[:link]}")
      }
    }
  end

  def run
    (0..3).each {|idx|
      crawl_gyhd(idx)
    }
    mail
    save_activities
  end

  # Crawl the GongYiHuoDong lists on cwikids website
  # There are 4 categories:
  # tid=0 -- ZhuTiHuoDong
  # tid=1 -- XiaoHuoBanJuLeBu
  # tid=2 -- JiaZhangKeTang
  # tid=3 -- XiaoHuoBanJuChang
  def crawl_gyhd(tid)
    gyhd_path = "/Activity/More?tid=#{tid}"
    @logger.info("Crawling GYHD - #{tid}")
    resp = @httpclient.get(gyhd_path)
    doc  = Nokogiri::HTML.parse(resp.body)
    doc.xpath("//dl[@class='gyhdlist']").each { |node|
      title    = node.xpath("./dd/a/@title").text()
      location = node.xpath("./dd[2]").text()
      time     = node.xpath("./dd[3]").text()
      reg      = node.xpath("./dd[4]").text()
      reg      = reg.gsub!("报名时间：", '').strip
      link     = node.xpath("./dd/a/@href").text()
      if reg == "报名结束" or @known_activities.include?(link)
        next
      end
      @new_activity << { :title => title, :location => location, :time => time,
                         :reg   => reg, :link => link }
    }
    @logger.info("Crawling GYHD - completed")
  end

  def mail
    subject = "中国福利会少年宫活动"
    body = ""
    if @new_activity.empty?
      @logger.info "No new activity found. Exiting."
      return
    else
      @new_activity.each {|node|
        body += "#{node[:title]}, #{HOST}#{node[:link]}\n"
      }
    end

    @mailclient.send(:subject => subject, :body => body)
  end
end

if __FILE__ == $0
  crawler = Cwikids_Crawler.new
  crawler.run
end