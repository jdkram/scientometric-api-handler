require 'minitest/autorun'

require_relative '../lib/api_caller'

class TestAltmetric < Minitest::Unit::TestCase

  PMID = '24889601'

	def test_successful_altmetric_request
    VCR.use_cassette('altmetric_success') do
      article = get_altmetric(PMID, false) # Poll Altmetric
      assert_match /massive-scale emotional contagion/, article[:title] # Title correct?
      assert_equal '10.1073/pnas.1320040111', article[:doi] # DOI correct?
      assert_match /SUCCESS/, article[:STATUS] # Great success
    end
	end

  def test_no_altmetric_entry
    VCR.use_cassette('altmetric_no_entry') do
      article = get_altmetric('invalid_id', false) # Send it a meaningless ID
      assert_match /NO ENTRY/, article[:STATUS] # Should fail without stalling
      assert_equal nil, article[:similar_age_journal_3m_percentile] # Check hash still keys, albeit empty
    end
  end

end