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

  #ipm = invoices per merchant; not the same as the method invoices_by_merchant
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
    bar = two_standard_deviations_above(invoices_per_merchant.values)
    invoices_per_merchant.find_all do |merchant_id, invoice|
      if invoice > bar
        @se.merchants.find_by_id(merchant_id)
      end
    end
  end

  def find_bottom_merchants_by_invoice_count
    bar = two_standard_deviations_below(invoices_per_merchant.values)
    invoices_per_merchant.find_all do |merchant_id, invoice|
      if invoice < bar
        @se.merchants.find_by_id(merchant_id)
      end
    end
  end

  def group_by_day_of_the_week
    day_of_the_week.inject(Hash.new(0)) do |hash, day|
      hash[day] += 1
      hash
    end
  end

  def find_top_days_by_invoice_count
    values = group_by_day_of_the_week.values
    bar = (average(values) + standard_deviation(values)).round
    group_by_day_of_the_week.select do |day, count|
      if count > bar
        day
      end
    end.keys
  end

  def find_invoice_status(status)
    invoices = @se.invoices.all.count
    by_status = @se.invoices.find_all_by_status(status).count
    ((by_status / invoices.to_f) * 100).round(2)
  end
#--------------------Iteration 4 Merchant Analytics--------------------------
  #ibd = invoice items by date; not the same as the method invoices_items_by_invoice_date
  def find_total_revenue_by_date(date)
    iibd = invoice_items_by_invoice_date(date)
    @se.invoice_items.all.inject(0) do |sum, invoice_item|
      if iibd.include?(invoice_item.invoice_id)
        sum += (invoice_item.unit_price * invoice_item.quantity)
      end
        sum
    end
  end

  def find_top_revenue_earners(top_merchants)
    merchants = sort_merchants_by_revenue.map do |merchant_id, revenue|
      @se.merchants.find_by_id(merchant_id)
    end.compact
    merchants.reverse.slice(0..(top_merchants - 1))
  end

  def sort_merchants_by_revenue
    merchants_by_revenue.sort_by do |merchant_id, revenue|
      revenue
    end.to_h
  end

  def find_merchants_ranked_by_revenue
    sort_merchants_by_revenue.map do |merchant_id, revenue|
      @se.merchants.find_by_id(merchant_id)
    end.reverse.compact
  end

  def merchants_by_revenue
    invoices_by_merchant.each_with_object({}) do |(id, invoices), revenue|
      invoice_totals_by_merchant(id, invoices, revenue)
      revenue
    end
  end

  def invoice_totals_by_merchant(id, invoices, total)
    total[id] = invoices.inject(0) do |sum, invoice|
      if invoice_paid_in_full?(invoice.id)
        sum += invoice_total(invoice.id)
      else
        sum
      end
    end
  end

end
