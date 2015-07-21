require 'minitest/autorun'

require_relative '../lib/api_handler'

class TestPMIDorDOI < Minitest::Unit::TestCase

  SAMPLE_PMID = '123456'
  SAMPLE_DOI = 'DOI/a.DOI.here'

  def test_identify_a_pmid
    assert_equal 'pmid', pmid_or_doi(SAMPLE_PMID)
    assert_equal 'doi', pmid_or_doi(SAMPLE_DOI)
  end

end
