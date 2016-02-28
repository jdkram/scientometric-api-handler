require 'minitest/autorun'

require_relative './vcr_setup'

class TestCheckPmid < Minitest::Unit::TestCase

  CORRECT_PMIDS = %w(
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
  17488234 17484599 427)

  def test_accepts_correct_pmids
    CORRECT_PMIDS.each do |pmid|
      assert_equal check_id(pmid, 'epmc'), true
    end
  end

  INCORRECT_PMIDS = %w(
  131218243253
  j
  123ko4
  x2
  :hello
  29.4
  )

  def test_rejects_incorrect_pmids
    INCORRECT_PMIDS.each do |pmid|
      assert_equal check_id(pmid, 'epmc'), false
    end
  end
end

class TestCheckORCIDid < Minitest::Unit::TestCase

  CORRECT_ORCID_IDS = %w(
    0000-0002-1694-233X
    0000-0001-5109-3700
    0000-0002-1825-0097)

  def test_accepts_correct_orcid_ids
    CORRECT_ORCID_IDS.each do |id|
      assert_equal check_id(id, 'orcid'), true
    end
  end

  INCORRECT_ORCID_IDS = %w(
    00-0002-1694-233X
    seventy_four
    0000-0002-1825-0090
  )

  def test_rejects_incorrect_orcid_ids
    INCORRECT_ORCID_IDS.each do |id|
      assert_equal check_id(id, 'orcid'), false
    end
  end

end
