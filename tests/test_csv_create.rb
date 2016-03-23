require 'minitest/autorun'
require 'vcr'
require 'csv'

require_relative './vcr_setup'

class TestCSVCreate < Minitest::Unit::TestCase

  def test_api_required
    assert_raises(ArgumentError) {csv_create ('./input/test.csv')}
  end

  def test_file_must_exist
    assert_raises(Errno::ENOENT) {csv_create('non-existent.csv', api: :altmetric)}
  end
  
  def test_csv_create_accepts_good_pmids
    VCR.use_cassette('epmc_good_pmids', :record => :new_episodes) do
      input_csv = './tests/test_good_pmids.csv'
      output_csv = './tests/test_good_pmids_output.csv'
      csv_create(input_csv , output_csv: output_csv, api: :epmc)
      input_length = CSV.open(input_csv).readlines.size
      output_length = CSV.open(output_csv).readlines.size
      assert_equal input_length, output_length # Should be same length, both have header rows
    end
  end  

  def test_csv_create_rejects_bad_pmids
    VCR.use_cassette('epmc_bad_pmids', :record => :new_episodes) do
        output_csv = './tests/test_bad_pmids_output.csv'
        csv_create('./tests/test_bad_pmids.csv', output_csv: output_csv, api: :epmc)
        CSV.open(output_csv, 'r') do |csv|
          assert_equal csv.readlines.size, 2 # Header row and one correct entry
        end
    end
  end

  def test_csv_create_accepts_good_orcid_ids
    # Just realised why this test takes so long with fresh calls...
    #   ... these are some of the most populated profiles around
    VCR.use_cassette('orcid_good_ids') do
      input_csv = './tests/test_good_orcid_ids.csv'
      output_csv = './tests/test_good_orcid_ids_output.csv'
      csv_create(input_csv, output_csv: output_csv, api: :orcid)
      input_length = CSV.open(input_csv).readlines.size
      output_length = CSV.open(output_csv).readlines.size
      assert_equal input_length+1, output_length # Should be same length, plus a header row
    end
  end

end
