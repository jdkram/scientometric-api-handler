require 'nokogiri'
require 'open-uri'
require 'json'

# Wouldn't need this at all we just put everything in the hashed JSON in to an activerecord.
ALTMETRIC_PRIMARY_ATTRIBUTES = {
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
  cited_by_wikipedia_count: 'cited_by_wikipedia_count',
  cited_by_linkedin_count: 'cited_by_linkedin_count',
  cited_by_f1000_count: 'cited_by_f1000_count', # Don't know about this
  cited_by_weibo_count: 'cited_by_weibo_count',
  cited_by_rdts_count: 'cited_by_rdts_count',
  cited_by_rh_count: 'cited_by_rh_count',
  subjects: 'subjects',
  top_quotes: 'tq',
  details_url: 'details_url',
  published_on: 'published_on'
}

ALTMETRIC_SECONDARY_ATTRIBUTES = [ 
# Update this with the 2nd level attributes (2 deep)
  :similar_age_journal_3m_percentile,
  :one_week_score,
  :six_month_score,
  :one_year_score
]

def get_altmetric(identifier, raw)
  # http://api.altmetric.com/docs/call_fetch.html for fuller details?
  url = create_url(identifier, :altmetric)
  identifier_type = classify_id(identifier) # Returns 'pmid' or 'doi' or 'unknown_id'
  url.sub!(/ID_TYPE/, identifier_type) # Construct URL based on correct identifier type
  begin
  article = {}
  case identifier_type
  when 'pmid'
    article[:pmid] = identifier
  when 'doi'
    article[:doi] = identifier
  when 'unknown_id'
  end

  altmetric_response = open(url)
  altmetric_json = JSON.parse(altmetric_response.read)
  ALTMETRIC_PRIMARY_ATTRIBUTES.each do
        |key,value| article[key.to_sym] = altmetric_json[value]
  end
  # Correct the below, ugly way of doing things
  if altmetric_json['context'] && altmetric_json['context']['similar_age_journal_3m']
    article[:similar_age_journal_3m_percentile] = altmetric_json['context']['similar_age_journal_3m']['pct']
  else
    article[:similar_age_journal_3m_percentile] = nil
  end
  article[:one_week_score] = altmetric_json['history']['1w']
  article[:six_month_score] = altmetric_json['history']['6m']
  article[:one_year_score] = altmetric_json['history']['1y']
  article[:STATUS] = "SUCCESS at #{Time.now}"
  return article

  # Now for the error handling
  rescue OpenURI::HTTPError => e
    if e.message == '404 Not Found'
      # Blank out the primary attributes
      ALTMETRIC_PRIMARY_ATTRIBUTES.each do
        |key,value| article[key] = nil
      end
      # Blank out the secondary attributes
      ALTMETRIC_SECONDARY_ATTRIBUTES.each do |symbol|
        article[symbol] = nil
      end
      article[:STATUS] = "NO ENTRY at #{Time.now}"
      return article
    else
      raise e
    end

  rescue Errno::ETIMEDOUT
    ALTMETRIC_PRIMARY_ATTRIBUTES.each do
        |key,value| article[key] = nil
      end
    ALTMETRIC_SECONDARY_ATTRIBUTES.each do |symbol|
      article[symbol] = nil
    end
    article[:STATUS] = "TIMEOUT at #{Time.now}"
  end
end


def get_altmetric_json(pmid)
  url = create_url(pmid, :altmetric)
  altmetric_response = open(url)
  altmetric_json = JSON.parse(altmetric_response.read)
  return altmetric_json
  # return altmetric_response.meta # Returns the daily rate stuff
end