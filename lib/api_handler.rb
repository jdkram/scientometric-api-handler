require 'nokogiri'
require 'open-uri'
require 'json'
require 'require_all'

require_relative '../config'
require_all 'lib' # Require everything in current directory
# Dir["./apis/*.rb"].each {|file| require_relative file } # Require each API file


BASEURLS = {
  altmetric: "http://api.altmetric.com/v1/ID_TYPE/QUERY#{ALTMETRIC_API_KEY}",
  epmc: "http://www.ebi.ac.uk/europepmc/webservices/rest/search/query=EXT_ID:QUERY&resultType=core",
  grist: "http://plus.europepmc.org/GristAPI/rest/get/query=gid:QUERY&resultType=core",
  orcid: "http://pub.orcid.org/v1.1/QUERY/orcid-profile"
}

GRIST_ATTRIBUTES = {
  grantid: '//grant//id',
  grantfundrefid: '//grant//fundrefid',
  grantfunder: '//grant//funder',
  granttitle: '//grant//title',
  grantholdername: '//person//familyname',
  grantholderinitials: '//person//initials',
  grantholdertitle: '//person//title'
}

ORCID_ATTRIBUTES = {
  id: '//path',
  creation_method: '//creation-method',
  submission_date: '//submission-date',
  last_modified_date: '//last-modified-date',
  claimed: '//claimed',
  given_names: '//given-names',
  family_name: '//family-name',
  credit_name: '//credit-name',
  other_name: '//other_name',
}

def create_url(identifier, type)
  return BASEURLS[type].sub(/QUERY/, identifier)
end

def pmid_or_doi(identifier)
  if identifier =~ /\// # If ID contains a slash, it's a DOI
    return 'doi'  
  elsif identifier =~ /\d{4,8}/
    return 'pmid'
  else 
    return 'unknown_id'
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
  article[:pmid] = if epmc_xml.at_xpath('//pmid') then epmc_xml.at_xpath('//pmid').content else '' end
  article[:doi] = if epmc_xml.at_xpath('//doi') then epmc_xml.at_xpath('//doi').content else '' end
  article[:title] = if epmc_xml.at_xpath('//result//title') then epmc_xml.at_xpath('//result//title').content else '' end
  article[:journal] = if epmc_xml.at_xpath('//journal//title') then epmc_xml.at_xpath('//journal//title').content else '' end
  article[:cited_by_count] = if epmc_xml.at_xpath('//citedbycount') then epmc_xml.at_xpath('//citedbycount').content else '' end
  authorlist = []
  epmc_xml.xpath('//author//fullname').each {
    |author| authorlist << author.content
  }
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

  article[:abstract] = if epmc_xml.at_xpath('//abstracttext') then epmc_xml.at_xpath('//abstracttext').content else '' end
  article[:dateofcreation] = if epmc_xml.at_xpath('//dateofcreation') then epmc_xml.at_xpath('//dateofcreation').content else '' end
  article[:authorstring] = if epmc_xml.at_xpath('//authorstring') then epmc_xml.at_xpath('//authorstring').content else '' end
  article[:firstauthor] = authorlist[0]
  article[:lastauthor] = authorlist[-1]
  article[:url] = if epmc_xml.at_xpath('//url') then epmc_xml.at_xpath('//url').content else '' end
  
  # First affiliation we can find

  article[:affiliation] = if epmc_xml.at_xpath('//result/affiliation') then epmc_xml.at_xpath('//result/affiliation').content else '' end

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

  article[:hasTextMinedTerms] = if epmc_xml.at_xpath('//hastextminedterms') then epmc_xml.at_xpath('//hastextminedterms').content else '' end
  article[:hasLabsLinks] = if epmc_xml.at_xpath('//haslabslinks') then epmc_xml.at_xpath('//haslabslinks').content else '' end

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

def get_orcid(id, raw)
  url = create_url(id, :orcid)
  article = {}
  orcid_xml = Nokogiri::HTML(open(url))
  ORCID_ATTRIBUTES.each do |key,value| # USE THIS STRUCTURE FOR OTHERS
    if orcid_xml.at_xpath(value)
     article[key] = orcid_xml.at_xpath(value).content
    else
      article[key] = nil
    end
  end
  article[:works_count] = orcid_xml.xpath('//orcid-work').length
  article[:STATUS] = "SUCCESS at #{Time.now}"
  return article
   
   rescue OpenURI::HTTPError => e
    if e.message == '404 Not Found'
      ORCID_ATTRIBUTES.each do |key, value| 
        article[key] = nil
      end
      article[:works_count] = nil
      article[:STATUS] = "NO ENTRY at #{Time.now}"
      return article
    else
      raise e
    end

    rescue Errno::ETIMEDOUT => e
      ORCID_ATTRIBUTES.each do |key, value| 
        article[key] = nil
      end
      article[:works_count] = nil
      article[:STATUS] = "TIMEOUT at #{Time.now}"
      return article
end

def call_api(id, api, raw: false)
  api = api.to_sym
  case api
  when :epmc
    get_epmc(id, raw)
  when :altmetric
    get_altmetric(id, raw)
  when :orcid
    get_orcid(id, raw)
  else
    raise ArgumentError, "Not a valid API"
  end
end

