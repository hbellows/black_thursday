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

  def find_total_revenue_by_date(date)
    invoices_by_date = invoice_items_by_invoice_date(date)
    @se.invoice_items.all.inject(0) do |sum, invoice_item|
      require "pry"; binding.pry
      if invoices_by_date.include?(invoice_item.invoice_id)
        sum += (invoice_item.unit_price * invoice_item.quantity)
      end
        sum
    end
  end

end
