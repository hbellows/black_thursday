# frozen_string_literal: true
class Transaction

  attr_reader :id,
              :invoice_id,
              :created_at

  attr_accessor :credit_card_number,
                :credit_card_expiration_date,
                :result,
                :updated_at

  def initialize(transaction_data)
    @id = transaction_data[:id].to_i
    @invoice_id = transaction_data[:invoice_id].to_i
    @credit_card_number = transaction_data[:credit_card_number]
    @credit_card_expiration_date = transaction_data[:credit_card_expiration_date]
    @result = transaction_data[:result].to_sym
    @created_at = Time.parse(transaction_data[:created_at].to_s)
    @updated_at = Time.parse(transaction_data[:updated_at].to_s)
  end
end
