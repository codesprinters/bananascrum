namespace :app do
  namespace :invoices do
    desc "Fetch daily EURPLN rate and store it into the database"
    task :fetch_rate => [ :environment ]  do
      url = URI.parse('http://nbp.pl/kursy/xml/LastA.xml')
      req = Net::HTTP::Get.new(url.path)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }
      
      doc = REXML::Document.new(res.body)
      root = doc.root
      publish_date = root.elements['data_publikacji'].text
      rate = nil
      root.each_element('//pozycja') do |pozycja|
        code = pozycja.elements['kod_waluty'].text
        next unless code == "EUR"
        rate = pozycja.elements['kurs_sredni'].text.gsub(',','.')
      end
      
      raise "EUR rate not found!" unless rate
      
      EurRate.create!(:rate => rate, :publish_date => publish_date)
    end
  
    desc "Find appropriate EURPLN rate" 
    task :set_rate => [ :environment ] do
      @rate = EurRate.find(:first, :conditions => [ "publish_date < ?", Date.today.to_s(:db) ], :order => "publish_date DESC")
      unless @rate
        raise "Appropriate EURPLN rate not found in the database"
      end
      puts "Using rate #{@rate.rate} published on #{@rate.publish_date}"
    end
  
    desc "Generate PDFs for invoices"
    task :generate => [ :set_rate ] do
      DomainChecks.disable do
        Invoice.without_pdfs.each do |invoice|
          invoice.generate_pdfs(@rate)
        end
      end
    end
  end
end