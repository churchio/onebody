class DonationTransaction < ActiveRecord::Base
  def amount_as_currency
    "$ %.2f" % (amount.to_f / 100)
  end

  def formatted_created_at
    created_at.strftime('%B %d, %Y')
  end
end
