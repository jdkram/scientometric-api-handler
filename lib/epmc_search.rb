require 'nokogiri'
require 'open-uri'
require 'json'
require 'csv'
require 'smarter_csv'
require 'colorize'
require 'require_all'
require 'Date'

require_all 'lib'

# query = 'GRANT_AGENCY:"Wellcome Trust"'

def epmc_search(job_name: , query:)
  if query.nil?
    puts "Please enter a valid EPMC query.".colorize(:red)
    exit
  end

  # Job handling
  query = query.to_s
  url = URI.encode(create_url(query, :epmc_search))
  puts url
  epmc_xml = Nokogiri::HTML(open(url))
  log = "./input/#{job_name}.log"
  output_csv = "./output/#{job_name}.csv"

  if File.exists?(log)
    search = eval(File.read(log))
  else
    sample_result = epmc_xml.xpath('//result')[0] # for headers
    CSV.open(output_csv, "w") do |csv|
      headers = epmc_headers(result: sample_result)
      csv << headers
    end
    search = {} # a hash defining our search and its progress
    search[:job_name] = job_name
    search[:query] = query
    search[:total_results] = get_xpath(epmc_xml,'//hitcount')
    search[:num_pages] = (search[:total_results].to_i / 25.0).ceil
    search[:progress] = {}
    (1..search[:num_pages].to_i).each do |page|
      search[:progress][page.to_s] = ""
    end
    save_search_progress(file: log, search: search) # save init log
  end

  times = [] # time per search in ms, for estimating completion
  search[:progress].each do |page, status|
    if /complete/ =~ status
      next
    else
      begin
        tries ||= 5
        t1 = Time.now
        puts "#{t1.strftime("%H:%M")}: Processing page #{page}...".colorize(:yellow)
        epmc_xml = get_epmc_page(query: query, page: page)
        results = epmc_xml.xpath('//result')
        articles = []
        results.each do |result|
          articles << process_epmc_result(result: result)
        end
        CSV.open(output_csv, "a") do |csv|  
          articles.each {|a| csv << a.values}
        end
        search[:progress][page] = "complete"
        t2 = Time.now
        diff = time_diff_milli(t1,t2)
        times << diff
        avg_time_in_ms = times.inject{ |sum, el| sum + el }.to_f / times.size
        num_left = search[:num_pages].to_i - page.to_i
        finish_time = t2 + (avg_time_in_ms / 1000 * num_left)
        puts "#{t2.strftime('%H:%M')}: Page #{page} / #{search[:num_pages]} complete taking #{(diff/1000.0).round(1)}s.".colorize(:green)
        puts "Approximate completion time:#{finish_time}."
        save_search_progress(file: log, search: search)
      rescue OpenURI::HTTPError => e
        if e.message == '502 Proxy Error'
          puts "Connection failed, retrying...".colorize(:yellow)
          retry unless (tries -= 1).zero? # 5 tries per request
        end
      rescue Errno::ENETUNREACH => e
        if (tries -= 1).zero?
          puts "Connection failed, retrying...".colorize(:yellow)
          retry
        else
          puts "5 consecutive errors connecting: #{e.message}"
        end
      end
    end
  end
end

def save_search_progress(file:, search:)
    File.open(file, "w") do |io|
      io.puts(search)
    end
end


def country_search(list)
end

def get_epmc_page(query: , page:)
  baseurl ='http://www.ebi.ac.uk/europepmc/webservices/rest/search/query=QUERY&resulttype=core&page=PAGE'
  url = baseurl.sub(/QUERY/, query)
  url = url.sub(/PAGE/, page)
  url = URI.encode(url)
  # puts "Retrieving #{url}"
  page = Nokogiri::HTML(open(url))
  sleep 0.2
  return page
end

def epmc_headers(result: result)
  headers = process_epmc_result(result: result).keys
  headers.map {|k| k.to_s}
  return headers
end

def time_diff_milli(start, finish)
   x = (finish - start) * 1000.0
   return x.ceil
end
