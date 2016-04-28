require 'minitest/autorun'
require 'vcr'

require_relative './vcr_setup'

class TestEPMC < Minitest::Unit::TestCase

  PMID = '9855500'
  SUCCESSFUL_EPMC_URL = 'http://www.ebi.ac.uk/europepmc/webservices/rest/search/query=EXT_ID:9855500&resulttype=core'
	
  def test_url_creation # Are we creating the URLs correctly?
    url = create_url(PMID, :epmc)
    assert_equal url, SUCCESSFUL_EPMC_URL
  end

  def test_doi # Testing a single article ot ensure DOI retrieval works
    VCR.use_cassette('epmc') do
      epmc_hash = get_epmc_by_pmid(PMID, false)
      assert_equal epmc_hash[:doi], '10.1212/wnl.51.6.1546'
    end
  end

  def test_handle_xml_no_content
    VCR.use_cassette('epmc_no_abstract') do
      epmc_hash = call_api('23450616', :epmc) # Entry w/ no abstract
      assert_equal epmc_hash[:abstract], '' # Key created, but no value
    end
  end

end
