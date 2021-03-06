module Chart
  def self.transactions_volume(days, bank)
    debits = Transaction.select('DATE(date) as day, SUM(amount) as sum')
      .where(receiver_id: bank.id)
      .where('date > ?', Time.current - days.days)
      .group('day')
    credits = Transaction.select('DATE(date) as day, SUM(amount) as sum')
      .where(buyer_id: bank.id)
      .where('date > ?', Time.current - days.days)
      .group('day')
    LazyHighCharts::HighChart.new('graph') do |f|
      f.title(text: I18n.t(:last_transactions, days: days))
      f.xAxis(categories: debits.map { |t| t.day.strftime('%a %e') })
      f.series(name: I18n.t(:debits), yAxis: 0, data: debits.map { |t| t.sum / 100 })
      f.series(name: I18n.t(:credits), yAxis: 0, data: credits.map { |t| t.sum / 100 })
      f.yAxis [{ title: { text: I18n.t(:euros) } }]
      f.chart(defaultSeriesType: 'column')
    end
  end

  def self.best_consumers(days, bank)
    consumers = Transaction.select('trigramme, SUM(amount) as sum')
      .joins(:buyer)
      .where.not(accounts: { status: 2 })
      .where(receiver_id: bank.id)
      .where('date > ?', Time.current - days.days)
      .group(:buyer_id)
      .order('sum DESC')
      .limit(20)
    LazyHighCharts::HighChart.new('graph') do |f|
      f.title(text: I18n.t(:best_consumers, days: days))
      js_function = "'<a href=\"/account/' + this.value + '\">' + this.value + '</a>'"
      formatter = %|function() { return #{js_function}; }|.js_code
      f.xAxis(categories: consumers.map(&:trigramme), labels: { formatter: formatter, useHTML: true })
      f.series(name: I18n.t(:consumption), yAxis: 0, data: consumers.map { |t| t.sum / 100 })
      f.yAxis [{ title: { text: I18n.t(:euros) } }]
      f.chart(defaultSeriesType: 'column')
    end
  end

  def self.scatter_plot
    accounts = Account.where.not(status: 2).where('promo >= 2000')
    non_smokers = accounts.where('total_clopes = 0')
    smokers = accounts.where('total_clopes > 0')
    non_smokers_data = non_smokers.map { |a| { x: a.balance / 100, y: a.promo, tri: a.trigramme, promo: a.promo } }
    smokers_data = smokers.map { |a| { x: a.balance / 100, y: a.promo, tri: a.trigramme, promo: a.promo } }
    LazyHighCharts::HighChart.new('graph') do |f|
      f.title(text: I18n.t(:trigrammes_balance))
      f.series(name: I18n.t(:non_smoker), color: 'rgba(119, 152, 191, .5)', data: non_smokers_data, turboThreshold: 0)
      f.series(name: I18n.t(:smoker), color: 'rgba(223, 83, 83, .5)', data: smokers_data, turboThreshold: 0)
      f.xAxis(min: -500, max: 500, plotLines: [{ color: '#C0D0E0', width: 1, value: 0 }])
      # f.xAxis(min: -500, max: 500, plotLines: [{ color: '#C0D0E0', width: 1, value: 0 }], type: 'logarithmic')
      f.yAxis(title: { text: I18n.t(:promo) }, min: 2000, max: Time.now.utc.year)
      f.chart(defaultSeriesType: 'scatter')
      f.plotOptions(scatter: { tooltip: { headerFormat: '<b>{series.name}</b><br>', pointFormat: '[{point.promo}] {point.tri}: {point.x} €' } })
    end
  end

  def self.cigarettes_volume
    data = Clope.order(quantite: :desc).all.map { |c| { name: c.marque, y: c.quantite } }
    quantite = Clope.all.map(&:quantite).sum
    LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(defaultSeriesType: 'pie')
      f.title(text: I18n.t(:cigarettes_volume) + ': ' + quantite.to_s + ' ' + I18n.t(:packs))
      f.series(data: data)
      f.tooltip(pointFormat: "{point.y} #{I18n.t(:packs)} ({point.percentage:.2f}%)")
    end
  end

  def self.cigarettes_turnover
    data = Clope.order(quantite: :desc).all.map { |c| { name: c.marque, y: c.quantite.to_i * c.prix.to_i / 100 } }
    turnover = Clope.all.map { |c| c.quantite.to_i * c.prix.to_i / 100 }.sum
    LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(defaultSeriesType: 'pie')
      f.title(text: I18n.t(:cigarettes_turnover) + ': ' + turnover.to_s + ' €')
      f.series(data: data)
      f.tooltip(pointFormat: '{point.y}€ ({point.percentage:.2f}%)')
    end
  end

  def self.heat_map(days, chart_global)
    data = (0..6).map { |day| (0..23).map { |hour| [hour, day, 0] } }
    Transaction.where('date > ?', Time.current - days.days).each do |t|
      data[t.date.wday - 1][t.date.hour][2] += 1
    end
    data = data.flatten(1)
    data.each { |item| item[2] = (item[2] / 2).to_i }
    background = chart_global.options[:chart]['backgroundColor']
    background_color = if background.nil?
                         '#FFFFFF'
                       elsif background.class == String
                         background
                       else
                         background['stops'][0][1]
                       end
    LazyHighCharts::HighChart.new('graph') do |f|
      f.chart(type: 'heatmap')
      f.title(text: I18n.t(:heat_map_title, days: days))
      f.xAxis(categories: (0..23).map { |h| "#{h}-#{h + 1}h" })
      f.yAxis(categories: %w(Lundi Mardi Mercredi Jeudi Vendredi Samedi Dimanche), reversed: true, title: nil)
      f.series(data: data)
      f.tooltip(headerFormat: nil, pointFormat: '{point.value} transactions')
      f.colorAxis(min: 0, minColor: background_color, maxColor: chart_global.options[:colors][0])
      f.legend(align: 'right', layout: 'vertical')
    end
  end

  def self.theme(chart_theme, theme)
    filename = chart_theme || (%w(darkly slate solar).include?(theme) ? 'dark_unica' : 'grid_light')
    file = File.read(Rails.root.join('app', 'assets', 'stylesheets', 'highcharts_themes', filename + '.json'))
    json = JSON.parse(file)
    LazyHighCharts::HighChartGlobals.new do |f|
      json.each do |k, v|
        f.public_send(k, v)
      end
    end
  end
end
