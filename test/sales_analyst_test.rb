# frozen_string_literal: true

require './test/test_helper'
require './lib/sales_analyst'
require './lib/sales_engine'
require 'pry'

class SalesAnalystTest < Minitest::Test

  def setup
    @se = SalesEngine.from_csv({
      items:          './mock_data/items_test_data.csv',
      merchants:      './mock_data/merchants_test_data.csv',
      invoices:       './mock_data/invoices_test_data.csv',
      invoice_items:  './mock_data/invoice_items_test_data.csv',
      transactions:   './mock_data/transactions_test_data.csv',
      customers:      './mock_data/customers_test_data.csv'
      })
    @sa = SalesAnalyst.new(@se)
  end

  def test_it_exists
    assert_instance_of SalesAnalyst, @sa
  end
  # -----------------------ITERATION ONE UNIT TESTS--------------------------
  def test_it_can_create_an_instance_of_sales_engine
    assert_instance_of SalesEngine, @sa.se
  end

  def test_it_can_group_items_by_merchant
    result = @sa.group_items_by_merchant
    assert_equal 9, result.length
    assert_equal 3, result[12334185].length
  end

  def test_it_can_return_items_per_merchant
    result = @sa.items_per_merchant
    assert_equal 9, result.length
    assert_equal 3, result[0]
  end

  def test_it_can_count_items_per_merchant
    assert_equal 1, @sa.items_per_merchant[1]
  end

  def test_it_can_find_the_average_number_of_items_per_merchant
    assert_equal 1.22, @sa.average_items_per_merchant
  end

  def test_it_can_find_average_items_per_merchant_standard_deviation
    assert_equal 0.67, @sa.average_items_per_merchant_standard_deviation
  end

  def test_it_can_find_merchants_with_high_item_count
    assert_equal 0, @sa.merchants_with_high_item_count.length
  end

  def test_it_can_select_merchant_ids_over_standard_deviation
    assert_equal 1, @sa.select_merchant_ids_over_standard_deviation.length
    assert_instance_of Fixnum, @sa.select_merchant_ids_over_standard_deviation[-1]
    assert_instance_of Fixnum, @sa.select_merchant_ids_over_standard_deviation[0]
  end

  def test_it_can_find_average_item_price_for_merchant
    assert_equal 0.03, @sa.average_item_price_for_merchant(12334105)
    assert_instance_of BigDecimal, @sa.average_item_price_for_merchant(12334105)
  end

  def test_it_can_find_average_average_price_per_merchant
    assert_equal 167.35, @sa.average_average_price_per_merchant.to_f
  end

  def test_it_can_find_average_item_price
    assert_equal 136.94, @sa.average_item_price
  end

  def test_it_can_calculate_standard_deviation_for_prices
    assert_instance_of BigDecimal, @sa.average_price_standard_deviation
    assert_equal 136.94, @sa.average_item_price
  end

  def test_it_can_find_golden_items
    assert_equal 1, @sa.golden_items.length
  end
  # -------------------ITERATION TWO-----------------------------------
  def test_it_can_group_invoices_by_merchant
    assert_equal 10, @sa.invoices_by_merchant.first[-1].count
  end

  def test_it_can_return_average_invoices_per_merchant
    assert_equal 9.25, @sa.average_invoices_per_merchant
  end

  def test_it_can_find_the_number_of_invoices_per_merchant
    assert_equal 10, @sa.invoices_per_merchant.first[-1]
  end

  def test_it_can_find_standard_deviation_of_avg_invoices_per_merchant
    assert_equal 4.08, @sa.average_invoices_per_merchant_standard_deviation
  end

  def test_it_can_find_merchants_with_invoices_two_std_deviations_above_mean
    assert_equal 1, @sa.top_merchants_by_invoice_count.size
  end

  def test_it_can_find_merchants_with_invoices_two_std_deviations_below_mean
    assert_equal 0, @sa.bottom_merchants_by_invoice_count.size
  end

  def test_it_can_find_day_of_the_week_from_date
    assert_equal 'Monday', @sa.day_of_the_week[0]
  end

  def test_it_can_group_by_day_of_the_week
    assert_equal 10, @sa.group_by_day_of_the_week.first[-1]
  end

  def test_it_can_find_top_days_by_invoice_count
    assert_equal ['Monday'], @sa.top_days_by_invoice_count
  end

  def test_it_can_calculate_percentages_based_invoice_status
    assert_equal 29.73, @sa.invoice_status(:pending)
    assert_equal 54.05, @sa.invoice_status(:shipped)
    assert_equal 16.22, @sa.invoice_status(:returned)
  end
  # -------------------------ITERATION THREE UNIT TESTS----------------------
  def test_it_can_find_invoice_by_id
    assert_instance_of Invoice, @sa.find_invoice(1)[0]
    assert_equal 12335938, @sa.find_invoice(1)[0].merchant_id
  end

  def test_invoice_paid_in_full?
    assert_equal true, @sa.invoice_paid_in_full?(74)
    assert_equal true, @sa.invoice_paid_in_full?(2969)
  end

  def test_invoice_total
    assert_equal 0.2106777E5, @sa.invoice_total(1)
  end
  # -------------------------ITERATION FOUR UNIT TESTS----------------------
  def test_it_can_calculate_total_revenue_by_date
    assert_equal 21067.77, @sa.total_revenue_by_date(Time.parse('2009-02-07')).to_f
  end

  def test_it_can_calculate_top_revenue_earners
    expected = @sa.top_revenue_earners
    assert_equal 4, expected.count
    assert_equal 12334113, expected[0].id
  end

  def test_it_can_sort_revenue_by_merchant
    assert_equal 87036.01, @sa.revenue_by_merchant(12334113).to_f
  end

  def test_merchants_with_pending_invoices
    assert_instance_of Merchant, @sa.merchants_with_pending_invoices[0]
    assert_instance_of Merchant, @sa.merchants_with_pending_invoices[-1]
    assert_equal 4, @sa.merchants_with_pending_invoices.length
  end

  def test_it_can_rank_merchants_by_revenue
    expected = @sa.merchants_ranked_by_revenue
    assert_equal 4, expected.count
    assert_equal 12334113, expected[0].id
    assert_equal 12335938, expected[3].id
  end

  def test_merchants_with_pending_invoices
    assert_instance_of Merchant, @sa.merchants_with_pending_invoices[0]
    assert_instance_of Merchant, @sa.merchants_with_pending_invoices[-1]
    assert_equal 4, @sa.merchants_with_pending_invoices.length
  end

  def test_merchants_with_only_one_item
    assert_instance_of Merchant, @sa.merchants_with_only_one_item[0]
    assert_instance_of Merchant, @sa.merchants_with_only_one_item[-1]
    assert_equal 1, @sa.merchants_with_only_one_item.length
  end

  def test_merchants_with_only_one_item_registered_in_month
    assert_instance_of Merchant, @sa.merchants_with_only_one_item_registered_in_month("December")[0]
    assert_instance_of Merchant, @sa.merchants_with_only_one_item_registered_in_month("December")[-1]
    assert_equal 1,  @sa.merchants_with_only_one_item_registered_in_month("December").length
  end

  def test_most_sold_item_for_merchant
    assert_instance_of Item, @sa.most_sold_item_for_merchant(12334105)[0]
  end

  def test_best_item_for_merchant
    assert_instance_of Item, @sa.best_item_for_merchant(12335938)
    assert_equal 1, @sa.best_item_for_merchant(12335938)
  end

end
