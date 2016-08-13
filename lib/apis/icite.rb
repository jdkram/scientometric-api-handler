require 'require_all'
require 'open-uri'
require 'csv'
require 'json'
require 'colorize'

ICITE_URL = "https://icite.od.nih.gov/api/pubs?pmids="
ICITE_FIELDS = ["pmid", "authors", "citation_count", "citations_per_year", "expected citations_per_year", "field_citation_rate", "is_research_article", "journal", "nih_percentile", "relative_citation_ratio", "title", "year"]

def get_rcrs(pmids)
  url = ICITE_URL + pmids
  icite_response = open(url)
  icite_json = JSON.parse(icite_response.read)
  articles = icite_json["data"]
  return articles
end

def batch_process_pmids_in_icite(input_csv:, output_csv:)
  pmids = CSV.read(input_csv, {headers: true})
  pmids = pmids.to_a.flatten
  pmids.shift if pmids.first =~ /pmid/ # Remove first row if it's a header called 'pmid'
  CSV.open(output_csv, "a") { |csv| csv << ICITE_FIELDS }
  num_blocks = (pmids.length / 200) # block 0 counts, no need to ceil
  puts "Beginning #{num_blocks} queries..."
  (0..num_blocks).each do |i|
    begin
    tries ||= 5
    str = pmids[i*200...(i+1)*200].join(',') # e.g. 0 to 199, 200 to 399
    articles = get_rcrs(str)
    CSV.open(output_csv, "a") do |csv|  
      articles.each do |article|
        csv << article.values
      end
    end
      puts "Added #{articles.length} articles - block #{i}/#{num_blocks}".colorize(:green)
    sleep 1
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

