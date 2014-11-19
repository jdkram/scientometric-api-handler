require 'minitest/autorun'
require 'vcr'
require 'csv'

require_relative '../lib/csv_creator'
require_relative './vcr_setup'

class TestCSVCreate < Minitest::Unit::TestCase

  def test_api_required
    assert_raises(ArgumentError) {csv_create ('../input/test.csv')}
  end

  def test_file_must_exist
    assert_raises(Errno::ENOENT) {csv_create('non-existent.csv', api: :altmetric)}
  end

  def test_csv_create_rejects_bad_ids
    VCR.use_cassette('epmc_bad_pmids') do
        output_csv = './tests/test_bad_pmids_output.csv'
        csv_create('./input/test_bad_pmids.csv', output_csv: output_csv, api: :epmc)
        CSV.open(output_csv, 'r') do |csv|
          puts csv.methods
        end
    end
  end
end
