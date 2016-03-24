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

  query = query.to_s
  url = create_url(query, :epmc_search)
  url = URI.encode(url)
  epmc_xml = Nokogiri::HTML(open(url))
  log = "./input/#{job_name}"
  output_csv = "./output/#{job_name}.csv"

  search = {}
  search[:total_results] = get_xpath(epmc_xml,'//hitcount')
  search[:num_pages] = (search[:total_results].to_i / 25.0).ceil
  search[:progress] = {}
  (1..search[:num_pages].to_i).each do |page|
    page = page.to_s
    search[:progress][page] = ""
  end

  sample_result = epmc_xml.xpath('//result')[0]

  if File.exists?(log)
    search = eval(File.read(log))
    else
    save_search_progress(file: log, search: search)
    CSV.open(output_csv, "w") do |csv|
      headers = epmc_headers(result: sample_result)
      puts headers
      csv << headers
    end
  end

  search[:progress].each do |page, status|
    if /complete/ =~ status
      next
    else
      t1 = Time.now
      puts "#{t1.strftime("%H:%S")}: Processing page #{page}...".colorize(:yellow)
      epmc_xml = get_epmc_page(query: query, page: page)
      results = epmc_xml.xpath('//result')
      articles = []
      results.each do |result|
        articles << process_epmc_result(result: result)
      end
      CSV.open(output_csv, "a") do |csv|  
        articles.each do |a|
          csv << a.values
        end
      end
      
      search[:progress][page] = "complete"
      t2 = Time.now
      diff = time_diff_milli(t1,t2)
      puts "#{t2.strftime('%H:%S')}: Page #{page} / #{search[:num_pages]} complete taking #{diff}ms".colorize(:green)
      save_search_progress(file: log, search: search)
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


def process_epmc_result(result: , raw: false, follow_labslinks: false)
  epmc_xml = result

  ## PARSE BASIC ARTICLE METADATA ##
  article = {}
  article[:pmid] = get_xpath(epmc_xml,'.//pmid')
  article[:doi] =  get_xpath(epmc_xml,'.//doi')
  article[:title] = get_xpath(epmc_xml,'./title')
  article[:journal] = get_xpath(epmc_xml,'.//journal//title')
  article[:cited_by_count] = get_xpath(epmc_xml,'.//citedbycount')
  article[:affiliation] = get_xpath(epmc_xml, './affiliation')
  
  authorlist, pubtypes = [], []
  epmc_xml.xpath('.//pubtype').each {
    |pubtype| pubtypes << pubtype.content
  }
  article[:pubtypes] = if pubtypes.empty? then article[:pubtypes] = '' else article[:pubtypes] = pubtypes end
  
  idlist = []
  epmc_xml.xpath('.//authoridlist/authorid').each {
    | authorid | idlist << authorid.content
  }
  article[:author_ids] = if idlist.empty? then '' else idlist end
  
  meshheadings = []
  epmc_xml.xpath('.//descriptorname').each {
    |heading| meshheadings << heading.content
  }
  article[:mesh_headings] = if meshheadings.empty? then '' else meshheadings end

  article[:abstract] = get_xpath(epmc_xml,'.//abstracttext')
  article[:dateofcreation] = get_xpath(epmc_xml,'.//dateofcreation')
  article[:authorstring] = get_xpath(epmc_xml,'.//authorstring')
  epmc_xml.xpath('.//author//fullname').each do |author|  
    authorlist << author.content
  end
  
  article[:firstauthor] = authorlist[0]
  first_author_xml = epmc_xml.xpath('.//author').first.to_s 
  firstauthor_affiliation_match = /\<affiliation\>([^<]+)\<\/affiliation\>/.match(first_author_xml)
  if firstauthor_affiliation_match
    article[:firstauthor_affiliation] = firstauthor_affiliation_match[1]
  else
    article[:firstauthor_affiliation] = ''
  end

  article[:lastauthor] = authorlist[-1]
  last_author_xml = epmc_xml.xpath('.//author').last.to_s
  lastauthor_affiliation_match = /\<affiliation\>([^<]+)\<\/affiliation\>/.match(last_author_xml)
  if lastauthor_affiliation_match
    article[:lastauthor_affiliation] = lastauthor_affiliation_match[1] 
    else
    article[:lastauthor_affiliation] = ''
  end

  article[:url] = if epmc_xml.at_xpath('.//url') then epmc_xml.at_xpath('.//url').content else '' end
  
  
  article[:author_affiliations] = []
  epmc_xml.xpath('.//author//affiliation').each do |affiliation|
    affiliation = affiliation.to_s
    affiliation_match = /\<affiliation\>([^<]+)\<\/affiliation\>/.match(affiliation)
    if affiliation_match
      # puts "adding affiliation: #{affiliation_match[1]}"
      article[:author_affiliations] << affiliation_match[1] 
    end
  end
  article[:author_affiliations].uniq!

  ## PARSE GRANT METADATA ##
  article[:number_of_grants] = epmc_xml.xpath('.//grant').length
  article[:all_grants] = []
  article[:WT_grants] = []
  article[:WT_six_digit_grants] = []
  epmc_xml.xpath('.//grant').each do |grant|  
    grant = grant.to_s
    grant_id_match = /\<grantid\>([^<]+)\<\/grantid\>/.match(grant)
    agency_match = /\<agency\>([^<]+)\<\/agency\>/.match(grant)
    # If we have a funder...
    if agency_match then
      agency = agency_match[1]
      # If we have a grant...
      if grant_id_match then
        grant_id = grant_id_match[1]
        str = "#{agency}: #{grant_id}"
        # Special treatment for WT grants
        if agency == 'Wellcome Trust'
          article[:WT_grants] << grant_id
          # Could be more specific than this, but lots of variants 
          # e.g. WT 087535MA, 096822/Z/11/Z
          six_digit_grant_match = /(\d{5,6})/.match(grant_id)
          if six_digit_grant_match
            article[:WT_six_digit_grants] << six_digit_grant_match[1]
          end
        end
      else
        # No grant num, but funder
        str = "#{agency_match[1]}: N/A"
      end
      article[:all_grants] << str
    end
    article[:WT_six_digit_grants].uniq!
  end

  article[:hasTextMinedTerms] = get_xpath(epmc_xml,'.//hastextminedterms')
  article[:hasLabsLinks] = get_xpath(epmc_xml,'.//haslabslinks')

  if follow_labslinks
    if article[:hasLabsLinks] == 'Y' then
      labs_url = 'http://www.ebi.ac.uk/europepmc/webservices/rest/MED/PMID/labsLinks'
      labs_url = labs_url.sub(/PMID/, pmid)
      labs_xml = Nokogiri::HTML(open(labs_url))
      labs_links_names = []
      labs_xml.xpath('.//name').each do |name|
        labs_links_names << name.content
      end
        article[:labsLinks] = labs_links_names
    else
        article[:labsLinks] = ''
    end

  ## EXAMINE DATABASE METADATA
    if epmc_xml.at_xpath('.//hasdbcrossreferences') && epmc_xml.at_xpath('.//hasdbcrossreferences').content == 'Y' then
      article[:hasDbCrossReferences] = 'Y'
      dbnames = []
      epmc_xml.xpath('.//dbname').each do |dbname|
        dbnames << dbname.content
      end
      article[:dbCrossReferenceList] = dbnames
    else
      article[:hasDbCrossReferences] = 'N'
      article[:dbCrossReferenceList] = ''
    end
  end

  if raw then # Inefficient to have run all the stuff to generate article then return epmc_xml, 
              # ... but then I don't really care as this is for testing
    return epmc_xml
  else
    return article
  end
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
