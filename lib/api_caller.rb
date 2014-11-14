# API Caller #

require 'nokogiri'
require 'open-uri'
require 'json'

require_relative '../config'

################################################################
# API CALLING
################################################################
# Grab that EPMC data

# URL to retrieve human-readable HTML
PUBMED_URL_BASE = 'http://www.ncbi.nlm.nih.gov/pubmed/?term='

# Retrieves XML from EPMC
EPMC_URL_BASE = 'http://www.ebi.ac.uk/europepmc/webservices/rest/search/query='
EPMC_URL_TAIL = '&resultType=core'

GRIST_URL_BASE = 'http://plus.europepmc.org/GristAPI/rest/get/query='
GRIST_URL_TAIL = '&resultType=core'

ALTMETRIC_URL_BASE = 'http://api.altmetric.com/v1/pmid/'
# ALTMETRIC_API_KEY Loaded from config

ORCID_URL_BASE = 'http://pub.orcid.org/v1.1/'
ORCID_URL_TAIL = '/orcid-profile'

TEST_PMIDS = %w(
  18243253 18217840 18085873 18077465
  18070950 18061407 18059267 18039035
  18005474 17998437 17988420 17984343
  17980006 17973103 17959777 17955446
  17955208 17940814 17940553 17920642
  17919952 17907847 17897464 17713391
  17878762 17873222 17855376 17845723
  17826852 17805508 17676498 17729146
  17720888 17697477 17662150 17654599
  17636079 17618414 17608818 17584500
  17583990 17569739 17554342 17552381
  17542115 17533769 17526833 17519421
  17510272 17508343 17505772 17490403
  17488234 17484599)

@test_pmid = TEST_PMIDS.sample # Grab a random test PMID

# Wouldn't need this at all we just put everything in the hashed JSON in to an activerecord.
ALTMETRIC_TOPLEVEL_ATTRIBUTES = {
  title: 'title',
  doi: 'doi',
  pmid: 'pmid',
  nlmid: 'nlmid',
  publisher_subjects: 'publisher_subjects',
  score: 'score',
  abstract: 'abstract',
  abstract_source: 'abstract_source',
  added_on: 'added_on',
  posts: 'cited_by_posts_count',
  journal: 'journal',
  readers_count: 'readers_count',
  url: 'url',
  is_oa: 'is_oa',
  cited_by_accounts_count: 'cited_by_accounts_count',
  cited_by_fbwalls_count: 'cited_by_fbwalls_count',
  cited_by_feeds_count: 'cited_by_feeds_count',
  cited_by_gplus_count: 'cited_by_gplus_count',
  cited_by_tweeters_count: 'cited_by_tweeters_count',
  cited_by_policies_count: 'cited_by_policies_count',
  cited_by_msm_count: 'cited_by_msm_count',
  cited_by_peer_review_sites_count: 'cited_by_peer_review_sites_count',
  subjects: 'subjects',
  # similar_age_journal_3m_percentile: 'context', # Need to handle subelements somehow
  top_quotes: 'tq',
  details_url: 'details_url',
  published_on: 'published_on'
              # "similar_age_this_journal_3m": {
              #   selected quotes
              #   geo
              #   # Where are they getting demographic data from?
              #   # Researcher / practitioner
              #   demographic # location important
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

def remove_tag(string)
  string.gsub(/\<[^\<]+\>/, '')
end


def get_epmc(pmid, raw: false)
  # Add sanitisation
  pmid = pmid.to_s
  # break unless pmid =~ /\d{8}/
  url = EPMC_URL_BASE + pmid + EPMC_URL_TAIL
  epmc_xml = Nokogiri::HTML(open(url))
  article = {}
  article[:pmid] = pmid
  article[:doi] = epmc_xml.at_xpath('//doi').content
  article[:title] = remove_tag(epmc_xml.at_xpath('//result//title').to_s.chomp)
  article[:journal] = remove_tag(epmc_xml.at_xpath('//journal//title').to_s.chomp)
  authorlist = []
  epmc_xml.xpath('//author//fullname').each {
    |author| authorlist << remove_tag(author.to_s)
  }
  pubtypes = []
  epmc_xml.xpath('//pubtype').each {
    |pubtype| pubtypes << remove_tag(pubtype.to_s)
  }

  (1..10).each do |n|
    id_key = ('grant_' + n.to_s + '_id').to_sym
    agency_key = ('grant_' + n.to_s + '_agency').to_sym
    
    grant_xml = epmc_xml.xpath('//grant')[n-1].to_s
    grantid_regex = /\<grantid\>([^<]+)\<\/grantid\>/
    agency_regex = /\<agency\>([^<]+)\<\/agency\>/

    grantid_match = grantid_regex.match(grant_xml)
    agency_match = agency_regex.match(grant_xml)

    article[:authorstring] = remove_tag(epmc_xml.at_xpath('//authorstring').to_s.chomp)
    article[:firstauthor] = authorlist[0]
    article[:lastauthor] = authorlist[-1]
    article[:url] = remove_tag(epmc_xml.at_xpath('//url').to_s.chomp)
    # First affiliation we can find
    article[:affiliation] = remove_tag(epmc_xml.at_xpath('//result/affiliation').to_s.chomp)
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
  article[:abstract] = remove_tag(epmc_xml.at_xpath('//abstracttext').to_s.chomp)
  article[:dateofcreation] = remove_tag(epmc_xml.at_xpath('//dateofcreation').to_s.chomp)
  if raw then
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
    article["#{src}_citation_count".to_sym] = remove_tag(epmc_xml.at_xpath('//hitcount').to_s)
  else
    sources.each do |source|
      url = 'http://www.ebi.ac.uk/europepmc/webservices/rest/' + source + '/' + pmid + '/citations'
      epmc_xml = Nokogiri::HTML(open(url))
      article["#{source}_citation_count".to_sym] = remove_tag(epmc_xml.at_xpath('//hitcount').to_s)
      sleep 1
    end
  end
end

def get_altmetric(pmid)
  # http://api.altmetric.com/docs/call_fetch.html for fuller details?
  url = ALTMETRIC_URL_BASE + pmid + ALTMETRIC_API_KEY
  begin
  article = {}
  article[:pmid] = pmid
  altmetric_response = open(url)
  altmetric_json = JSON.parse(altmetric_response.read)
  ALTMETRIC_TOPLEVEL_ATTRIBUTES.each do
        |key,value| article[("altmetric_" + key.to_s).to_sym] = altmetric_json[value]
  end
  # Correct the below, ugly way of doing things
  if altmetric_json['context'] && altmetric_json['context']['similar_age_journal_3m']
    article[:altmetric_similar_age_journal_3m_percentile] = altmetric_json['context']['similar_age_journal_3m']['pct']
  else
    article[:altmetric_similar_age_journal_3m_percentile] = nil
  end
  article[:altmetric_one_week_score] = altmetric_json['history']['1w']
  article[:altmetric_six_month_score] = altmetric_json['history']['6m']
  article[:altmetric_one_year_score] = altmetric_json['history']['1y']
  article[:altmetric_STATUS] = "SUCCESS at #{Time.now}"
  return article # keep changing this, check it before running

  rescue OpenURI::HTTPError => e
    if e.message == '404 Not Found'
      ALTMETRIC_TOPLEVEL_ATTRIBUTES.each do
        |key,value| article[("altmetric_" + key.to_s).to_sym] = nil
      end
      article[:altmetric_similar_age_journal_3m_percentile] = nil # Ugh. Correct this stuff.
      article[:altmetric_one_week_score] = nil
      article[:altmetric_six_month_score] = nil
      article[:altmetric_one_year_score] = nil
      article['altmetric_STATUS'] = "NO ENTRY at #{Time.now}"
      return article
    else
      raise e
    end
  rescue Errno::ETIMEDOUT
    ALTMETRIC_TOPLEVEL_ATTRIBUTES.each do
        |key,value| article[("altmetric_" + key.to_s).to_sym] = nil
      end
      article[:altmetric_similar_age_journal_3m_percentile] = nil # Ugh. Correct this stuff.
      article[:altmetric_one_week_score] = nil
      article[:altmetric_six_month_score] = nil
      article[:altmetric_one_year_score] = nil
      article['altmetric_STATUS'] = "TIMEOUT at #{Time.now}"
  end
end

def get_grist(grantid, raw: false)
  p = URI::Parser.new
  grantid = p.escape(grantid) # Should put this on other calls
  url = GRIST_URL_BASE + 'gid:' + grantid + GRIST_URL_TAIL
  grant = {}
  grist_xml = Nokogiri::HTML(open(url))  
  # puts "url: #{url}"
  GRIST_ATTRIBUTES.each do
   |key,value| grant["grist_" + key.to_s] = remove_tag(grist_xml.xpath(value)[0].to_s)
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

def get_altmetric_json(pmid)
  url = ALTMETRIC_URL_BASE + pmid + ALTMETRIC_API_KEY
  altmetric_response = open(url)
  altmetric_json = JSON.parse(altmetric_response.read)
  return altmetric_json
  # return altmetric_response.meta # Returns the daily rate stuff
end

def get_orcid(id, raw: false)
  id = id[/\d{4}-\d{4}-\d{4}-\d{4}/]
  url = ORCID_URL_BASE + id + ORCID_URL_TAIL
  orcid_xml = Nokogiri::HTML(open(url))
  article = {}
  ORCID_ATTRIBUTES.each do
     |key,value| article[("orcid_" + key.to_s).to_sym] = remove_tag(orcid_xml.xpath(value)[0].to_s)
  end
  article[:orcid_works_count] = orcid_xml.xpath('//orcid-work').length
  # TODO: transform this to create one entry per work?
  if raw
    return orcid_xml
  else
    return article
  end
end