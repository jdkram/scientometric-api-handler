require_relative '../lib/api_caller'
require 'minitest/autorun'

class TestAltmetric < Minitest::Unit::TestCase

  PMID = '24889601'

	def test_successful_altmetric_request
    VCR.use_cassette('altmetric_success') do
      article = get_altmetric(PMID, false)
      assert_match /massive-scale emotional contagion/, article[:title]
      assert_equal '10.1073/pnas.1320040111', article[:doi]
      assert_match /SUCCESS/, article[:STATUS]
    end
	end

  def test_no_altmetric_entry
    VCR.use_cassette('altmetric_no_entry') do
      article = get_altmetric('invalid_id', false)
      assert_match /NO ENTRY/, article[:STATUS]
      assert_equal nil, article[:similar_age_journal_3m_percentile]
    end
  end

end