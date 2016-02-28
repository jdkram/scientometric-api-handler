require 'minitest/autorun'
require 'vcr'
require 'require_all'

require_all 'lib'

require_relative './vcr_setup'

class TestEPMC < Minitest::Unit::TestCase

  def test_doi   
  end

  def test_handle_xml_no_content
    
  end

end
