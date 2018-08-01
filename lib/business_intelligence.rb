# frozen_string_literal: true

module BusinessIntelligence
  # ------------------Iteration 2 Business Intelligence-----------------------
  def invoices_by_merchant
    @se.invoices.all.group_by(&:merchant_id)
  end

  # ipm = invoices per merchant; not the same as invoices_by_merchant
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

  def find_top_merchants_by_invoice_count
    merchants = []
    bar = two_standard_deviations_above(invoices_per_merchant.values)
    invoices_per_merchant.find_all do |merchant_id, invoice|
      if invoice > bar
        merchants << @se.merchants.find_by_id(merchant_id)
      end
    end
    merchants
  end

  def find_bottom_merchants_by_invoice_count
    merchants = []
    bar = two_standard_deviations_below(invoices_per_merchant.values)
    invoices_per_merchant.each do |merchant_id, invoice|
      if invoice < bar
        merchants << @se.merchants.find_by_id(merchant_id)
      end
    end
    merchants
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
end
