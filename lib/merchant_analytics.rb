# frozen_string_literal: true
module MerchantAnalytics

  #--------------------Iteration 4 Merchant Analytics------------------------
  #ibd = invoice items by date; not the same as the method
  #invoices_items_by_invoice_date
  def find_total_revenue_by_date(date)
    iibd = invoice_items_by_invoice_date(date)
    @se.invoice_items.all.inject(0) do |sum, invoice_item|
      if iibd.include?(invoice_item.invoice_id)
        sum += (invoice_item.unit_price * invoice_item.quantity)
      end
        sum
    end
  end

  def invoice_items_by_invoice_date(date)
    invoices_by_date[date].each_with_object([]) do |invoice, dates|
      dates << invoice.id
      dates
    end
  end

  def invoices_by_date
    @se.invoices.all.group_by(&:created_at)
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

  #sets key value pair for merchants by revenue hash above
  def invoice_totals_by_merchant(id, invoices, hash)
    hash[id] = invoices.inject(0) do |sum, invoice|
      if invoice_paid_in_full?(invoice.id)
        sum += invoice_total(invoice.id)
      else
        sum
      end
    end
  end
end
