# A data transformation for Ichimoku Signals dropdown.

WITHIN_DAYS = 5
@logfile = "#{Rails.root}/log/ichimoku_signals.log"

class IchimokuSignalService
  attr_reader :data

  def initialize(within_days = WITHIN_DAYS)
    log 'INFO: IchimokuSignalServiceBegin'
    @output_file = "#{Rails.root}/config/ichimoku_signals_#{within_days}_days.yml"

    @data = {
              golden: [],
              symbols: [],
              above: [],
              inside: [],
              underneath: [],
              yellow: []
            }

    Ticker.all.each do |t|
      next if t.crossing.blank?
      t.crossing.golden_corosses.each do |g|
        # TODO: upgrade from serialization to dedicated table
        if g[:business_days_ago].to_i <= WITHIN_DAYS then
          date = g[:date]
          span_a = t.ichimoku_price.where(date: date).as_json.first['span_a']
          span_b = t.ichimoku_price.where(date: date).as_json.first['span_b']
          unless date.blank? || span_a.blank? || span_b.blank? then
            if g[:price] >= span_a then
              print 'A'
              @data[:above] << t.symbol
            end
            if g[:price] < span_a && g[:price] > span_b then
              print 'i'
              @data[:inside] << t.symbol
            end
            if g[:price] <= span_b then
              print 'u'
              @data[:underneath] << t.symbol
            end
            if span_b > span_a then
              print 'y'
              @data[:yellow] << t.symbol
            end
            @data[:symbols] << t.symbol.upcase
            @data[:golden] << [ t.symbol, g[:business_days_ago], g[:price] ]
          end
        end
      end
    end
    @data
  end

  def update
    if @data.empty? then
      log = 'ERROR: IchimokuSignalService.update ran with no @data!'
      return
    end
    begin
      puts "INFO: IchimokuSignalService writing #{@output_file}.."
      outfile = File.open(@output_file, 'w')
      outfile.puts @data.to_yaml
      outfile.close
    rescue => e
      log "ERROR: IchimokuSignalService: Could not write #{@output_file}! : " \
          "#{e}\n---\n##{e.backtrace}"
    end
  end

  private

  def log(message)
    puts message
    logger = Logger.new(@logfile, 10, 1024000, datetime_format: '%Y-%m-%d %H:%M:%S')
    logger.level = Logger::INFO
    logger.info "\n#{eval DBUG}\n#{message}"
    logger.close
    message
  end

end
