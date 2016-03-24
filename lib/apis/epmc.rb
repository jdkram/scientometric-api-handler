require 'nokogiri'
require 'open-uri'
require 'json'


def get_xpath(xml,path)
  path = path.downcase
  if xml.at_xpath(path) then
    return xml.at_xpath(path).content
  else
    return ''
  end
end

def get_epmc(pmid: , raw: false, follow_labslinks: true)
  # Add sanitisation
  pmid = pmid.to_s
  url = create_url(pmid, :epmc)
  epmc_xml = Nokogiri::HTML(open(url))
  epmc_xml = epmc_xml.xpath('//result')

  ## PARSE BASIC ARTICLE METADATA ##
  article = {}
  article[:pmid] = get_xpath(epmc_xml,'//pmid')
  article[:doi] =  get_xpath(epmc_xml,'//doi')
  article[:title] = get_xpath(epmc_xml,'/title')
  article[:journal] = get_xpath(epmc_xml,'//journal//title')
  article[:cited_by_count] = get_xpath(epmc_xml,'//citedbycount')
  article[:affiliation] = get_xpath(epmc_xml, './affiliation')
  
  authorlist, pubtypes = [], []
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
  epmc_xml.xpath('//author//fullname').each do |author|  
    authorlist << author.content
  end
  
  article[:firstauthor] = authorlist[0]
  first_author_xml = epmc_xml.xpath('//author').first.to_s 
  firstauthor_affiliation_match = /\<affiliation\>([^<]+)\<\/affiliation\>/.match(first_author_xml)
  if firstauthor_affiliation_match
    article[:firstauthor_affiliation] = firstauthor_affiliation_match[1]
  else
    article[:firstauthor_affiliation] = ''
  end

  article[:lastauthor] = authorlist[-1]
  last_author_xml = epmc_xml.xpath('//author').last.to_s
  lastauthor_affiliation_match = /\<affiliation\>([^<]+)\<\/affiliation\>/.match(last_author_xml)
  if lastauthor_affiliation_match
    article[:lastauthor_affiliation] = lastauthor_affiliation_match[1] 
    else
    article[:lastauthor_affiliation] = ''
  end

  article[:url] = if epmc_xml.at_xpath('//url') then epmc_xml.at_xpath('//url').content else '' end
  
  
  article[:author_affiliations] = []
  epmc_xml.xpath('//author//affiliation').each do |affiliation|
    affiliation = affiliation.to_s
    affiliation_match = /\<affiliation\>([^<]+)\<\/affiliation\>/.match(affiliation)
    if affiliation_match
      # puts "adding affiliation: #{affiliation_match[1]}"
      article[:author_affiliations] << affiliation_match[1] 
    end
  end
  article[:author_affiliations].uniq!

  ## PARSE GRANT METADATA ##
  article[:number_of_grants] = epmc_xml.xpath('//grant').length
  article[:all_grants] = []
  article[:WT_grants] = []
  article[:WT_six_digit_grants] = []
  epmc_xml.xpath('//grant').each do |grant|  
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
          six_digit_grant_match = /(\d{6})/.match(grant_id)
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

  article[:hasTextMinedTerms] = get_xpath(epmc_xml,'//hastextminedterms')
  article[:hasLabsLinks] = get_xpath(epmc_xml,'//haslabslinks')

  if follow_labslinks
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

GRIST_ATTRIBUTES = {
  grantID: '//grant//id',
  grantFundrefID: '//grant//fundrefid',
  grantFunder: '//grant//funder',
  grantTitle: '//grant//title',
  grantAbstract: '//grant//abstract',
  grantType: '//grant/type',
  grantStream: '//grant/stream',
  grantholderName: '//person//familyname',
  grantholderInitials: '//person//initials',
  grantholderTitle: '//person//title',
  grantholderOrcid: '//person//alias',
  grantStartDate: '//grant//startdate',
  grantEndDate: '//grant//enddate',
  grantInstitutionName: '//institution//name'
}
# Example URL for GRIST schema:
# http://plus.europepmc.org/GristAPI/rest/get/query=gid:200347&resultType=core

def get_grist(grantid, raw: false)
  p = URI::Parser.new
  grantid = p.escape(grantid) # Should put this on other calls
  url = create_url(grantid, :grist)
  grant = {}
  grist_xml = Nokogiri::HTML(open(url))  
  # puts "url: #{url}"
  GRIST_ATTRIBUTES.each do
   |key,path| grant[key] = get_xpath(grist_xml,path)
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