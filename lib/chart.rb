module Chart
  def self.transactions_volume(days, bank)
    debits = Transaction.select('DATE(date) as day, SUM(ABS(price)) as sum')
      .where.not(id: bank.id)
      .where(id2: bank.id)
      .where('price < 0')
      .where('date > ?', Time.current - days.days)
      .group('day')
    credits = Transaction.select('DATE(date) as day, SUM(price) as sum')
      .where.not(id: bank.id)
      .where(id2: bank.id)
      .where('price > 0')
      .where('date > ?', Time.current - days.days)
      .group('day')
    LazyHighCharts::HighChart.new('graph') do |f|
      f.title(text: "Transactions des #{days} derniers jours")
      f.xAxis(categories: debits.map { |t| t.day.strftime('%a %e') })
      f.series(name: 'Débits', yAxis: 0, data: debits.map { |t| t.sum / 100 })
      f.series(name: 'Crédits', yAxis: 0, data: credits.map { |t| t.sum / 100 })
      f.yAxis [{ title: { text: 'Euros' } }]
      f.chart(defaultSeriesType: 'column')
    end
  end

  def self.best_consumers(days, bank)
    consumers = Transaction.select('trigramme, SUM(ABS(price)) as sum')
      .joins(:payer)
      .where.not(accounts: { status: 2 })
      .where.not(id: bank.id)
      .where(id2: bank.id)
      .where('price < 0')
      .where('date > ?', Time.current - days.days)
      .group(:id)
      .order('sum DESC')
      .limit(20)
    LazyHighCharts::HighChart.new('graph') do |f|
      f.title(text: "Meilleurs consommateurs des #{days} derniers jours")
      f.xAxis(categories: consumers.map(&:trigramme))
      f.series(name: 'Consommation', yAxis: 0, data: consumers.map { |t| t.sum / 100 })
      f.yAxis [{ title: { text: 'Euros' } }]
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
      f.title(text: '"Répartition des soldes de trigrammes')
      f.series(name: 'Non Fumeur', color: 'rgba(119, 152, 191, .5)', data: non_smokers_data, turboThreshold: 0)
      f.series(name: 'Fumeur', color: 'rgba(223, 83, 83, .5)', data: smokers_data, turboThreshold: 0)
      f.xAxis(min: -500, max: 500, plotLines: [{ color: '#C0D0E0', width: 1, value: 0 }])
      f.yAxis(title: { text: 'Promo' }, min: 2000, max: Time.now.utc.year)
      f.chart(defaultSeriesType: 'scatter')
      f.plotOptions(scatter: { tooltip: { headerFormat: '<b>{series.name}</b><br>', pointFormat: '[{point.promo}] {point.tri}: {point.x} €' } })
    end
  end
end