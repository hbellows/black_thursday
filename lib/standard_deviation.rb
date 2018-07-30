# frozen_string_literal: true
module StandardDeviation

  def average(info)
    (info.inject(:+) / info.count.to_f).round(2)
  end

  def variance(info)
    info.map {|number| (average(info) - number) ** 2}
  end

  def standard_deviation(info)
    Math.sqrt(average(variance(info))).round(2)
  end

  def two_standard_deviations_above(info)
    average(info) + standard_deviation(info) * 2
  end

  def two_standard_deviations_below(info)
    average(info) - standard_deviation(info) * 2
  end

end
