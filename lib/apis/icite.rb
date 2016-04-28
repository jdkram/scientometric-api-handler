require 'require_all'
require 'mechanize'
require 'csv'

ICITE_URL = "https://icite.od.nih.gov/analysis"

def get_rcrs(pmids)
  agent = Mechanize.new
  agent.pluggable_parser.default = Mechanize::Download
  page = agent.get(ICITE_URL)
  form = page.forms.first
  form.fields.first.value = pmids
  # pp page
  page = agent.submit(form, form.buttons.first)
  tr = page.parser.xpath("//tr[contains(@class, 'pub-data')]")
  articles = []
  tr.each do |tr|
    article = {}
    article[:pmid] = tr.attr('data-pmid')
    article[:cited_per_year] = tr.attr('data-cited-per-year')
    article[:rcr] = tr.attr('data-rcr')
    articles << article
  end
  return articles
end

def batch_process_pmids_in_icite(input_csv:, output_csv:)
  pmids = CSV.read(input_csv, {headers: true})
  pmids = pmids.to_a.flatten
  CSV.open(output_csv, "a") { |csv| csv << ['pmid', 'cited_per_year', 'RCR'] }
  num_blocks = (pmids.length / 200) # block 0 counts, no need to ceil
  puts "Beginning #{num_blocks} queries..."
  (0..num_blocks).each do |i|
    begin
    str = pmids[i*200...(i+1)*200].join(' ') # e.g. 0 to 199, 200 to 399
    articles = get_rcrs(str)
    CSV.open(output_csv, "a") do |csv|  
      articles.each do |article|
        csv << article.values
      end
    end
      puts "Added #{articles.length} articles - block #{i}/#{num_blocks}".colorize(:green)
    sleep 1
    rescue Mechanize::ResponseCodeError
      puts "Error asking for batch beginning #{pmids[i*200].to_s} - block #{i}/#{num_blocks}"
      sleep 1
    next
    end
  end
end
