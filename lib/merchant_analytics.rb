module MerchantAnalytics

  def items_by_merchant
    @se.items.all.group_by(&:merchant_id)
  end

  def invoices_by_merchant
    @se.invoices.all.group_by(&:merchant_id)
  end

  def transactions_by_invoice
    @se.transactions.all.group_by(&:invoice_id)
  end

  def invoices_by_date
    @se.invoices.all.group_by(&:created_at)
  end

  def invoice_items_by_invoice_id
    @se.invoice_items.all.group_by(&:invoice_id)
  end

  def invoices_per_merchant
    ipm = invoices_by_merchant
    ipm.inject(ipm) do |hash, (merchant_id, invoices)|
      hash[merchant_id] = invoices.count
      hash
    end
  end

  def day_of_the_week
    @se.invoices.all.map do |invoice|
      Date::DAYNAMES[invoice.created_at.wday]
    end
  end

  def invoice_items_by_invoice_date(date)
    invoices_by_date[date].each_with_object([]) do |invoice, dates|
      dates << invoice.id
      dates
    end
  end

  def find_top_merchants_by_invoice_count
    top_merchants = []
    bar = two_standard_deviations_above(invoices_per_merchant.values)
    invoices_per_merchant.each do |merchant_id, invoice|
      if invoice > bar
        merchant = @se.merchants.find_by_id(merchant_id)
        top_merchants << merchant
      end
    end
    top_merchants
  end

  def find_bottom_merchants_by_invoice_count
    bottom_merchants = []
    bar = two_standard_deviations_below(invoices_per_merchant.values)
    invoices_per_merchant.each do |merchant_id, invoice|
      if invoice < bar
        merchant = @se.merchants.find_by_id(merchant_id)
        bottom_merchants << merchant
      end
    end
    bottom_merchants.compact
  end

  def group_by_day_of_the_week
    day_of_the_week.inject(Hash.new(0)) do |hash, day|
      hash[day] += 1
      hash
    end
  end

  def find_top_days_by_invoice_count
    top_days = []
    values = group_by_day_of_the_week.values
    bar = (average(values) + standard_deviation(values)).round
    group_by_day_of_the_week.each do |day, count|
      if count > bar
        top_days << day
      end
    end
    top_days
  end

  def find_invoice_status(status)
    invoices = @se.invoices.all.count
    by_status = @se.invoices.find_all_by_status(status).count
    ((by_status / invoices.to_f) * 100).round(2)
  end

  def invoice_paid_in_full?(invoice_id)
    return false if @transactions_by_invoice[invoice_id].nil?
    @transactions_by_invoice[invoice_id].any? do |transaction|
      transaction.result == :success
    end
  end

  def invoice_total(invoice_id)
    return nil unless invoice_paid_in_full?(invoice_id)
    invoice_by_id = group_invoice_items_by_invoice_id
    total_price = invoice_by_id[invoice_id].inject(0) do |collector, invoice|
      collector + (invoice.quantity * invoice.unit_price)
    end
    BigDecimal(total_price, 5)
  end

  def merchants_with_pending_invoices
    @invoices_by_merchant.each_with_object([]) do |(id, invoices), collector|
      invoices.each do |invoice|
        unless invoice_paid_in_full?(invoice.id)
          collector << @sales_engine.merchants.find_by_id(id)
        end
      end
      collector
    end.uniq
  end

  def find_total_revenue_by_date(date)
    invoices_by_date = invoice_items_by_invoice_date(date)
    @se.invoice_items.all.inject(0) do |sum, invoice_item|
      if invoices_by_date.include?(invoice_item.invoice_id)
        sum += (invoice_item.unit_price * invoice_item.quantity)
      end
        sum
    end
  end

  def top_revenue_earners(top_merchants)
    merchants = sort_merchants_by_revenue.map do |merchant_id, _revenue|
      @sales_engine.merchants.find_by_id(merchant_id)
    end
    merchants.reverse.slice(0..(top_merchants - 1))
  end

  def sort_merchants_by_revenue
    merchants_by_revenue.sort_by do |_merchant_id, revenue|
      revenue
    end.to_h
  end

  def merchants_ranked_by_revenue
    sort_merchants_by_revenue.map do |merchant_id, _revenue|
      @sales_engine.merchants.find_by_id(merchant_id)
    end.reverse
  end

  def merchants_by_revenue
    @invoices_by_merchant.each_with_object({}) do |(id, invoices), revenue|
      revenue[id] = invoices.inject(0) do |sum, invoice|
        if invoice_paid_in_full?(invoice.id)
          sum += invoice_total(invoice.id)
        else
          sum
        end
      end
      revenue
    end
  end

  def revenue_by_merchant(merchant_id)
    merchants_by_revenue[merchant_id]
  end

  def find_paid_invoices_per_merchant(id)
    @sales_engine.invoices.find_all_by_merchant_id(id).find_all do |invoice|
      invoice_paid_in_full?(invoice.id)
    end
  end

  def find_invoices_by_invoice_id(invoice_by_merchant)
    invoice_by_merchant.map do |invoice|
      @sales_engine.invoice_items.find_all_by_invoice_id(invoice.id)
    end.flatten
  end

  def find_item_quantities_sold_by_merchant(paid_invoice_items)
    paid_invoice_items.each_with_object(Hash.new(0)) do |invoice, sold|
      sold[invoice.item_id] += invoice.quantity
      sold
    end
  end

  def find_item_revenue_sold_by_merchant(paid_invoice_items)
    paid_invoice_items.each_with_object(Hash.new(0)) do |invoice, sold|
      sold[invoice.item_id] += invoice.quantity * invoice.unit_price
      sold
    end
  end

  def calculate_best_selling_item_by_merchant(merchant_items)
    merchant_items.each_with_object([]) do |(item, quantity), items|
      if quantity == merchant_items.values.max
        items << @sales_engine.items.find_by_id(item)
      end
      items
    end
  end

  def calculate_highest_revenue_item_by_merchant(revenue_by_item)
    revenue_by_item.max_by do |_item_id, revenue|
      revenue
    end
  end

  def find_paid_invoice_items_for_merchant(merchant_id)
    invoice_by_merchant = find_paid_invoices_per_merchant(merchant_id)
    find_invoices_by_invoice_id(invoice_by_merchant)
  end

  def most_sold_item_for_merchant(merchant_id)
    paid_invoice_items = find_paid_invoice_items_for_merchant(merchant_id)
    merchant_items = find_item_quantities_sold_by_merchant(paid_invoice_items)
    calculate_best_selling_item_by_merchant(merchant_items)
  end

  def best_item_for_merchant(merchant_id)
    paid_invoice_items = find_paid_invoice_items_for_merchant(merchant_id)
    revenue_by_item = find_item_revenue_sold_by_merchant(paid_invoice_items)
    item_id = calculate_highest_revenue_item_by_merchant(revenue_by_item)
    @sales_engine.items.find_by_id(item_id[0])
  end

end
