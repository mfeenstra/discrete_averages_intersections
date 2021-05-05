#!/usr/bin/env ruby
# Ruby on Rails, ActiveRecord model data, and Statistical Analysis of Momentum.
#
# Finds the golden cross and death crossings for a slow and fast moving average
# by comparing a 3-day sliding window (on a discrete set) for the inflection.
#
# matt.a.feenstra@gmail.com - copyright 2021
#################################################################################################
require_relative "#{ENV['HOME']}/marketmath/config/environment"
SYMBOL = ARGV[0] || 'aapl'

# ichimoku study involves 9 period tenkan and 26 period kijou rolling averages
long_averages = []
long_dates = []
Ticker.find_by(symbol: SYMBOL).ichimoku_price.order(:date).each { |long|
  unless long.tenkan.blank? || long.kijun.blank? then
    long_averages << long.tenkan
    long_dates << long.date
  end
}
short_averages = []
short_dates = []
Ticker.find_by(symbol: SYMBOL).ichimoku_price.order(:date).each { |short|
  unless short.kijun.blank? || short.tenkan.blank? then
    short_averages << short.kijun
    short_dates << short.date
  end
}

golden = []
death = []
skip_next = false

# compare 3 days at a time for intersection
short_averages.each.with_index(1) do |short, i|

  # only count first day of 2 consecutive crossover triggers (it's either this or the next day)
  if skip_next then
    # puts "SKIPPING #{i}"
    skip_next = false
    next
  end

  # don't do it if we're running off the end of the array
  unless long_averages[i - 1].blank? || long_averages[i + 1].blank? ||
         short_averages[i - 1].blank? || short_averages[i + 1].blank? then

    # significant figures are important because we're looking at the delta for the long and short average plots
    found_sigfigs = false
    dollar_magnitude = short_averages[i].round.to_s.size
    if (dollar_magnitude <= 1) && !found_sigfigs then round_digits = 4; found_sigfigs = true end
    if (dollar_magnitude == 2) && !found_sigfigs then round_digits = 3; found_sigfigs = true end
    if (dollar_magnitude == 3) && !found_sigfigs then round_digits = 2; found_sigfigs = true end
    if (dollar_magnitude == 4) && !found_sigfigs then round_digits = 1; found_sigfigs = true end
    if (dollar_magnitude >= 5) && !found_sigfigs then round_digits = 0; found_sigfigs = true end

    # 3 days in a row
    delta_prev = (long_averages[i - 1] - short_averages[i - 1]).round(round_digits)
    delta_middle = (long_averages[i] - short_averages[i]).round(round_digits)
    delta_next = (long_averages[i + 1] - short_averages[i + 1]).round(round_digits)

    # death cross when fast moves under the slow average
    if (delta_prev > 0.0) && (delta_next < 0.0) then
      # puts "golden cross up (#{short_dates.size - i} days ago): #{short_dates[i]} => prev: #{delta_prev} today: #{delta_middle} tomorrow: #{delta_next}"
      death << short_dates[i]
      skip_next = true
      next
    end

    # golden cross when the quick average moves up through and above the longer average
    if (delta_prev < 0.0) && (delta_next > 0.0) then
      # puts "death cross down (#{short_dates.size - i} days ago): #{short_dates[i]} => prev: #{delta_prev} today: #{delta_middle} tomorrow: #{delta_next}"
      golden << short_dates[i]
      skip_next = true
      next
    end


  end
end

puts "\n-- golden crosses --"
pp golden
puts "\n-- death crosses --"
pp death
