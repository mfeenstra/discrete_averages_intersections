class IchimokuCrossingsService
  attr_reader :symbol, :golden, :death
  def initialize(symbol)
    @symbol = symbol.to_s.downcase
    @death = []
    @golden = []
    skip_next = false
    average_data = Ticker.find_by(symbol: @symbol).ichimoku_price.order(:date)
    puts "INFO: CrossingService: calculating #{@symbol.upcase} (#{average_data.size} days).."
    average_data.each_with_index do |ichi, i|
      if skip_next then
        skip_next = false
        next
      end
      unless ichi.tenkan.blank? || ichi.kijun.blank? ||
             average_data[i - 1].tenkan.blank? || average_data[i + 1].blank? ||
             average_data[i - 1].kijun.blank? || average_data[i + 1].kijun.blank? then
        prices = Ticker.find_by(symbol: @symbol).price.order(:date)
        price = prices.find_by(date: ichi.date).close.to_f
        price_index = prices.pluck(:date).index(ichi.date)
        days_ago = prices.size - i
        delta_prev = (average_data[i - 1].tenkan - average_data[i - 1].kijun).round(sigfigs(price))
        delta_middle = (average_data[i].tenkan - average_data[i].kijun).round(sigfigs(price))
        delta_next = (average_data[i + 1].tenkan - average_data[i + 1].kijun).round(sigfigs(price))
        if (delta_prev > 0.0) && (delta_next < 0.0) then
          @death << {
                      index_day: price_index, date: ichi.date, business_days_ago: days_ago,
                      price: price, longavg: ichi.tenkan, shortavg: ichi.kijun
                    }
          skip_next = true
          next
        end
        if (delta_prev < 0.0) && (delta_next > 0.0) then
          @golden << {
                       index_day: price_index, date: ichi.date, business_days_ago: days_ago,
                       price: price, longavg: ichi.tenkan, shortavg: ichi.kijun
                     }
          skip_next = true
          next
        end
      end
    end
    puts "INFO: CrossingService golden crosses size: #{@golden.size}"
    puts "INFO: CrossingService death crosses size: #{@death.size}"
    rescue => e
      puts %(ERROR: CrossingService#initialize: #{e}\n---\n#{e.backtrace.join("\n")})
    end
  end

  private

  def sigfigs(price)
    dmag = price.round.to_s.size
    case
    when dmag <= 1
      return 4
    when dmag == 2
      return 3
    when dmag == 3
      return 2
    when dmag == 4
      return 1
    when dmag >= 5
      return 0
    else
      return 2
  end

end # class
