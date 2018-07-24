require './test/test_helper'
require './lib/merchant_repository'
require './lib/file_loader'


class MerchantRepositoryTest < Minitest::Test
  include FileLoader

  def setup
    @mock_data = [
        {id: 12334105,
        name: 'Shopin1901',
        created_at: '2010-12-10',
        updated_at: '2011-12-04'},
        {id: 12334112,
        name: 'Candisart',
        created_at: '2009-05-30',
        updated_at: '2010-08-29'},
        {id: 12334113,
        name: 'MiniatureBikez',
        created_at: '2010-03-30',
        updated_at: '2013-01-21'},
        {id: 12334115,
        name: 'LolaMarleys',
        created_at: '2008-06-09',
        updated_at: '2015-04-16'},
        {id: 12334123,
        name: 'Keckenbauer',
        created_at: '2010-07-15',
        updated_at: '2012-07-25'}
        ]

    @mr = MerchantRepository.new(@mock_data)
  end

  def test_it_exists
    assert_instance_of MerchantRepository, @mr
  end

  def test_it_can_return_all_merchants
    # skip
    assert_equal 5, @mr.all.count
    assert_equal 'Shopin1901', @mr.all[0].name
    assert_equal 'Keckenbauer', @mr.all[4].name
  end

  def test_it_can_find_merchant_by_id
    skip
    assert_instance_of Merchant, @mr.find_by_id(12334112)
  end

  def test_it_can_find_merchant_by_name
    skip
    search_1 = @mr.find_by_name('JEJUM')
    assert_equal @mr.all[7], search_1
    assert_equal true, search_1.name.include?('jejum')

    search_2 = @mr.find_by_name('MiniatureBikez')
    assert_equal @mr.all[2], search_2
    # assert_equal true, search_2.name.include?('miniaturebikez')
  end

  def test_it_can_find_all_merchants_with_matching_name_fragment
    skip
    search_1 = @mr.find_all_by_name('M')
    assert_equal 164, search_1.count
    # 201 instances of the letter 'M', but only 164 objects
    search_2 = @mr.find_all_by_name('mi')
    assert_equal 28, search_2.count

    search_3 = @mr.find_all_by_name('MINI')
    assert_equal 1, search_3.count
  end

  def test_it_can_create_a_new_id_number
    skip
    new_id = @mr.create_new_id_number

    assert_equal 12337412, new_id
  end

  def test_it_can_create_a_new_merchant
    skip
    new_merchant = @mr.create({:name => 'MockEtsyStore1'})

    assert_equal 'MockEtsyStore1', new_merchant.name
    assert_equal 12337412, new_merchant.id
    assert_equal new_merchant, @mr.all.last
    assert_equal 476, @mr.all.count
  end

  def test_it_can_update_a_merchant_name
    skip
    updated_merchant_1 = @mr.update(12337409, :name => 'CardsByMary&Kate')

    assert_equal 'CardsByMary&Kate', updated_merchant_1.name

    updated_merchant_2 = @mr.update(1234, :name => 'uh oh my id is not present')

    assert_equal 'Record not found.', updated_merchant_2
  end

  def test_it_can_delete_a_merchant_record
    skip
    sample_merchant = @mr.create({:name => 'SampleMerchant'})
    assert_equal 'SampleMerchant', sample_merchant.name
    assert_equal 12337412, sample_merchant.id
    assert_equal 476, @mr.all.count

    @mr.delete(12337412)
    assert_equal 475, @mr.all.count
  end
end
