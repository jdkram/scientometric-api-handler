require 'nokogiri'
require 'open-uri'
require 'json'

GRIST_ATTRIBUTES = {
  grantid: '//grant//id',
  grantfundrefid: '//grant//fundrefid',
  grantfunder: '//grant//funder',
  granttitle: '//grant//title',
  grantholdername: '//person//familyname',
  grantholderinitials: '//person//initials',
  grantholdertitle: '//person//title'
}

def get_xpath(xml,path)
  path = path.downcase
  if xml.at_xpath(path) then
    xml.at_xpath(path).content
  else
    ''
  end
end

def get_epmc(pmid, raw)
  # Add sanitisation
  pmid = pmid.to_s
  # break unless pmid =~ /\d{8}/
  url = create_url(pmid, :epmc)
  epmc_xml = Nokogiri::HTML(open(url))

  ## PARSE BASIC ARTICLE METADATA ##
  article = {}
  article[:pmid] = get_xpath(epmc_xml,'//pmid')
  article[:doi] =  get_xpath(epmc_xml,'//doi')
  article[:title] = get_xpath(epmc_xml,'//result//title')
  article[:journal] = get_xpath(epmc_xml,'//journal//title')
  article[:cited_by_count] = get_xpath(epmc_xml,'//citedbycount')
  authorlist = []
  pubtypes = []
  epmc_xml.xpath('//pubtype').each {
    |pubtype| pubtypes << pubtype.content
  }
  article[:pubtypes] = if pubtypes.empty? then article[:pubtypes] = '' else article[:pubtypes] = pubtypes end
  
  idlist = []
  epmc_xml.xpath('//authoridlist/authorid').each {
    | authorid | idlist << authorid.content
  }
  article[:author_ids] = if idlist.empty? then '' else idlist end
  
  meshheadings = []
  epmc_xml.xpath('//descriptorname').each {
    |heading| meshheadings << heading.content
  }
  article[:mesh_headings] = if meshheadings.empty? then '' else meshheadings end

  article[:abstract] = get_xpath(epmc_xml,'//abstracttext')
  article[:dateofcreation] = get_xpath(epmc_xml,'//dateofcreation')
  article[:authorstring] = get_xpath(epmc_xml,'//authorstring')
  epmc_xml.xpath('//author//fullname').each {
    |author| authorlist << author.content
  }
  article[:firstauthor] = authorlist[0]
  article[:lastauthor] = authorlist[-1]
  article[:url] = if epmc_xml.at_xpath('//url') then epmc_xml.at_xpath('//url').content else '' end
  
  # First affiliation we can find

  article[:affiliation] = get_xpath(epmc_xml,'//result/affiliation')

  ## PARSE GRANT METADATA ##
  # Gather info for up to 10 grants. Not elegant.
  (1..10).each do |n|
    id_key = ('grant_' + n.to_s + '_id').to_sym # Create a key for storage in the hash
    agency_key = ('grant_' + n.to_s + '_agency').to_sym # Create a key for storage in the hash
    grant_xml = epmc_xml.xpath('//grant')[n-1].to_s # Pull in the grant for this iteration

    grantid_match = /\<grantid\>([^<]+)\<\/grantid\>/.match(grant_xml) # Does it contain a grantid?
    agency_match = /\<agency\>([^<]+)\<\/agency\>/.match(grant_xml) # Does it contain an agency?

    if agency_match then
        article[agency_key] = agency_match[1]
      else
        article[agency_key] = 'N/A'
    end

    if grantid_match then
        article[id_key] = grantid_match[1]
      else
        article[id_key] = 'N/A'
    end
  end

  article[:hasTextMinedTerms] = get_xpath(epmc_xml,'//hastextminedterms')
  article[:hasLabsLinks] = get_xpath(epmc_xml,'//haslabslinks')

  if article[:hasLabsLinks] == 'Y' then
    labs_url = 'http://www.ebi.ac.uk/europepmc/webservices/rest/MED/PMID/labsLinks'
    labs_url = labs_url.sub(/PMID/, pmid)
    labs_xml = Nokogiri::HTML(open(labs_url))
    labs_links_names = []
    labs_xml.xpath('//name').each do |name|
      labs_links_names << name.content
    end
      article[:labsLinks] = labs_links_names
    else
      article[:labsLinks] = ''
    end

  ## EXAMINE DATABASE METADATA
  if epmc_xml.at_xpath('//hasdbcrossreferences') && epmc_xml.at_xpath('//hasdbcrossreferences').content == 'Y' then
    article[:hasDbCrossReferences] = 'Y'
    dbnames = []
    epmc_xml.xpath('//dbname').each do |dbname|
      dbnames << dbname.content
    end
    article[:dbCrossReferenceList] = dbnames
  else
    article[:hasDbCrossReferences] = 'N'
    article[:dbCrossReferenceList] = ''
  end
 
  if raw then # Inefficient to have run all the stuff to generate article then return epmc_xml, 
              # ... but then I don't really care as this is for testing
    return epmc_xml
  else
    return article
  end
end

def get_epmc_citations(pmid, src: false, raw: false)
  pmid = pmid.to_s
  article = {}
  article[:pmid] = pmid
  sources = %w(AGR CBA CTX ETH HIR MED PAT PMC)
  if src
  then
    url = 'http://www.ebi.ac.uk/europepmc/webservices/rest/' + source + '/' + pmid + '/citations'
    epmc_xml = Nokogiri::HTML(open(url))
    article["#{src}_citation_count".to_sym] = epmc_xml.at_xpath('//hitcount').content
  else
    sources.each do |source|
      url = 'http://www.ebi.ac.uk/europepmc/webservices/rest/' + source + '/' + pmid + '/citations'
      epmc_xml = Nokogiri::HTML(open(url))
      article["#{source}_citation_count".to_sym] = epmc_xml.at_xpath('//hitcount').content
      sleep 1
    end
  end
end


def get_grist(grantid, raw)
  p = URI::Parser.new
  grantid = p.escape(grantid) # Should put this on other calls
  url = create_url(grantid, :grist)
  grant = {}
  grist_xml = Nokogiri::HTML(open(url))  
  # puts "url: #{url}"
  GRIST_ATTRIBUTES.each do
   |key,value| grant[key] = grist_xml.xpath(value)[0].content
  end

  if raw then
    return grist_xml
  else
    return grant
  end

  rescue OpenURI::HTTPError => e
  if e.message == '404 Not Found'
    puts '404 error!'
  else
    raise e
  end
end