require 'minitest/autorun'
require 'vcr'

require_relative '../lib/api_caller'
require_relative './vcr_setup'

class TestEPMC < Minitest::Unit::TestCase

  PMID = '9855500'
  SUCCESSFUL_EPMC_URL = 'http://www.ebi.ac.uk/europepmc/webservices/rest/search/query=9855500&resultType=core'
	
  def test_url_creation
    url = create_url(PMID, :epmc)
    assert_equal(url, SUCCESSFUL_EPMC_URL)
  end

  def test_doi
    VCR.use_cassette('epmc') do
      epmc_hash = get_epmc(PMID)
      assert_equal(epmc_hash[:doi], '10.1212/wnl.51.6.1546') 
    end
  end

end