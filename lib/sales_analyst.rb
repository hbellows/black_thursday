# frozen_string_literal: true

require 'bigdecimal'
require 'bigdecimal/util'
require_relative 'business_intelligence'
require_relative 'standard_deviation'
require_relative 'merchant_analytics'

class SalesAnalyst
  include BusinessIntelligence
  include StandardDeviation
  include MerchantAnalytics

  attr_reader :se

  def initialize(sales_engine)
    @se = sales_engine
  end

  def group_items_by_merchant
    @se.items.all.group_by do |item|
      item.merchant_id
    end
  end

  def items_per_merchant
    group_items_by_merchant.values.map(&:count)
  end

  def average_items_per_merchant
    total_items = items_per_merchant.inject(0) do |sum, item_count|
      sum + item_count
    end
    ((total_items).round(2) / items_per_merchant.length.round(2)).round(2)
  end

  def average_items_per_merchant_standard_deviation
    mean = average_items_per_merchant
    length_less_one = items_per_merchant.length - 1
    diffed_and_squared = []
    items_per_merchant.each do |count|
      diffed_and_squared  << (count - mean)**2
    end
    sum = diffed_and_squared.inject(0) do |sum, number|
      number + sum
    end
    divided = sum / length_less_one
    return (divided ** (1.0/2)).round(2)
  end

  def select_merchant_ids_over_standard_deviation
    mean = average_items_per_merchant
    grouped = group_items_by_merchant
    selected_ids = []
    grouped.each do |key, value|
      if value.length > average_items_per_merchant_standard_deviation + mean
        selected_ids << key
      end
    end
    return selected_ids
  end

  def merchants_with_high_item_count
    merchants = []
    selected_ids = select_merchant_ids_over_standard_deviation
    @se.merchants.all.each do |merchant|
      if selected_ids.include?(merchant.id)
        merchants << merchant
      end
    end
    return merchants
  end

  def average_item_price_for_merchant(merchant_id_number)
    grouped = group_items_by_merchant
    items = grouped[merchant_id_number]
    prices = []
    items.each do |item|
      prices << item.unit_price_to_dollars
    end
    total = prices.inject(0.00) do |sum, price|
      sum + price
    end
    (total / prices.length).round(2).to_d
  end

  def average_average_price_per_merchant
    grouped = group_items_by_merchant
    ids = grouped.keys
    average_prices = ids.map do |id|
      average_item_price_for_merchant(id)
    end
    sum = average_prices.inject(0.00) do |sum, price|
      sum + price
    end
    return (sum / average_prices.length).round(2).to_d
  end

  def average_item_price
    prices = []
    @se.items.all.each do |item|
      prices << item.unit_price_to_dollars
    end
    total_prices = prices.inject(0) do |sum, price|
      sum + price
    end
    (total_prices / (prices.length)).round(2)
  end

  def average_price_standard_deviation
    mean = average_item_price
    prices = @se.items.all.map do |item|
      item.unit_price_to_dollars
    end
    length_less_one = prices.length - 1
    diffed_and_squared = []
    prices.each do |price|
      diffed_and_squared << ((price - mean) ** 2).round(2)
    end
    total_diffed_and_squared = diffed_and_squared.inject(0) do |sum, price|
      sum + price
    end
    divided = (total_diffed_and_squared / length_less_one)
    return (divided ** (1/2.00)).round(2).to_d
  end

  def golden_items
    mean = average_item_price
    golden_items = []
    @se.items.all.each do |item|
      if item.unit_price_to_dollars > mean + (average_price_standard_deviation * 2)
        golden_items << item
      end
    end
    return golden_items
  end
  # ----------------ITERATION TWO---------------------------------
  def average_invoices_per_merchant
    (@se.invoices.all.count / @se.merchants.all.count.to_f).round(2)
  end

  def average_invoices_per_merchant_standard_deviation
    standard_deviation(invoices_per_merchant.values)
  end

  def top_merchants_by_invoice_count
    find_top_merchants_by_invoice_count
  end

  def bottom_merchants_by_invoice_count
    find_bottom_merchants_by_invoice_count
  end

  def top_days_by_invoice_count
    find_top_days_by_invoice_count
  end

  def invoice_status(status)
    find_invoice_status(status)
  end
  # -------------------ITERATION THREE------------------------------------
  def find_invoice(invoice_id)
    selected = []
    @se.invoices.all.each do |invoice|
      if invoice.id == invoice_id
        selected << invoice
      end
    end
    return selected
  end

  def grab_all_transactions(invoice_id)
    invoice = find_invoice(invoice_id)
    result = []
    @se.transactions.all.each do |transaction|
      if transaction.invoice_id == invoice_id
        result << transaction
      end
    end
    return result
  end

  def invoice_paid_in_full?(invoice_id)
    transactions = grab_all_transactions(invoice_id)
    statuses = []
    transactions.each do |transaction|
      statuses << transaction.result
    end
    statuses.include?(:success)
  end

  def invoice_total(invoice_id)
   invoice_items = @se.invoice_items.find_all_by_invoice_id(invoice_id)
   total_price_per_pruchase = invoice_items.map do |invoice_item|
     invoice_item.quantity * invoice_item.unit_price
   end
   sum = total_price_per_pruchase.inject(0) do |total, cost|
     total + cost
   end
   BigDecimal(sum, 7)
 end
 # ----------------------ITERATION FOUR----------------------------------
  def total_revenue_by_date(date)
    find_total_revenue_by_date(date)
  end

  def top_revenue_earners(top_earners = 20)
    find_top_revenue_earners(top_earners)
  end

  def merchants_with_pending_invoices
    merchant_ids = []
    @se.invoices.all.each do |invoice|
      if invoice_paid_in_full?(invoice.id) == false
        merchant_ids << invoice.merchant_id
      end
    end
    merchants = []
    merchant_ids.each do |id|
      merchants <<  @se.merchants.find_by_id(id)
      end
    return merchants.compact.uniq
  end

  def merchants_ranked_by_revenue
    rank_merchants_by_revenue
  end

  def merchants_with_only_one_item
    result = @se.items.all.group_by do |item|
      item.merchant_id
    end
    merchant_ids = []
    result.each do |key, value|
      if value.length == 1
        merchant_ids << key
      end
    end
    merchants = []
    merchant_ids.each do |merchant_id|
      merchants << @se.merchants.find_by_id(merchant_id)
    end
    return merchants.compact
  end

  def merchants_with_only_one_item_registered_in_month(month)
    invoices_by_month = @se.invoices.all.group_by do |invoice|
      invoice.created_at.strftime('%B')
    end
    merchants_by_month = @se.merchants.all.group_by do |merchant|
      merchant.created_at.strftime('%B')
    end
    merchants_in_specified_month = merchants_by_month[month]
    one_item_in_month = []
    merchants_with_only_one_item.each do |merchant|
      if merchants_in_specified_month.include?(merchant)
        one_item_in_month << merchant
      end
    end
    return one_item_in_month
  end

  def revenue_by_merchant(merchant_id)
    merchants_by_revenue[merchant_id]
  end

  def most_sold_item_for_merchant(merchant_id)
    invoices_for_id = @se.invoices.all.find_all do |invoice|
      invoice.merchant_id == merchant_id
      end
    successful_invoices = []
    invoices_for_id.each do |invoice|
      if invoice_paid_in_full?(invoice.id)
        successful_invoices << invoice
        end
      end
     invoice_items = successful_invoices.map do |invoice|
       @se.invoice_items.find_all_by_invoice_id(invoice.id)
     end.flatten
     quantities_by_item_id = Hash.new(0)
     invoice_items.map do |invoice_item|
      quantities_by_item_id[invoice_item.item_id] += invoice_item.quantity
    end
     max = quantities_by_item_id.max_by do |item_id, quantity|
       quantity
     end
     max_quantity = max[1]
     ids_and_max_value = quantities_by_item_id.find_all do |id, quantity|
       quantity == max_quantity
     end.flatten
     ids = ids_and_max_value.map.with_index do |num, index|
       if num.to_s.length > 8
         ids_and_max_value.delete_at(index)
       end
     end
     items = []
     ids.each do |id|
      items << @se.items.find_by_id(id)
     end
     return items.compact
   end

   def best_item_for_merchant(merchant_id)
     grouped = @se.invoices.all.find_all do |invoice|
        invoice.merchant_id == merchant_id
      end
      invoice_items_paid_in_full = []
      grouped.each do |invoice|
        if invoice_paid_in_full?(invoice.id)
          invoice_items_paid_in_full << @se.invoice_items.find_all_by_invoice_id(invoice.id)
      end
    end.flatten
    grouped = invoice_items_paid_in_full.flatten.group_by do |invoice_item|
      invoice_item.item_id
      end
    grouped.map do |item_id, invoice_item|
      grouped[item_id] = (invoice_item[0].quantity.to_f * (invoice_item[0].unit_price.to_f.round(2))).round(2)
      end
    top_value = grouped.max_by do |item_id, invoice_value|
      invoice_value
      end
    item_ids = []
    top_value.each do |value|
      if value > 1000000
        item_ids << value
      end
    end
    items = []
    item_ids.each do |id|
      items << @se.items.find_by_id(id)
      end
      return items.compact.flatten.shift
  end

end
