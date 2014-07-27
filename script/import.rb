Well.delete_all

MAP = {
  days_in_operation: 8,
  gas: 10,
  gas_sold: 11,
  oil: 6,
  water: 7
}

def data(line)
  fields = line.split /\s+/
  params = MAP.inject({}) do |hsh, (name, index)|
    hsh[name] = fields[index]
    hsh
  end
  params
end

(2011..2013).each do |year|
  start = year == 2011 ? 10 : 1
  stop = year == 2013 ? 8 : 12

  (start..stop).each do |month|
    month_str = month < 10 ? "0#{month}" : month

    puts "NDIC Monthly data #{month}/#{year} PDF" if ENV['DEBUG']

    url = "https://www.dmr.nd.gov/oilgas/mpr/#{year}_#{month_str}.pdf"
    pdf_file = File.join(Rails.root, 'tmp', "#{year}_#{month_str}.pdf")
    text_file = File.join(Rails.root, 'tmp', "#{year}_#{month_str}.txt")

    unless File.exist?(pdf_file)
      puts "Downloading" if ENV['DEBUG']
      puts `curl #{url} > #{pdf_file}` if ENV['DEBUG']
    end

    unless File.exist?(text_file)
      puts 'Extracting...' if ENV['DEBUG']
      cmd = "java -jar tika-app-1.3.jar -t #{pdf_file} > #{text_file}"
      puts cmd if ENV['DEBUG']
      `#{cmd}`
    end

    src = File.read(text_file)
    lines = src.scan(/160-91-8-D-1H.*/)

    if lines.any?
      puts lines.first.split(/\s+/).inspect
      params = data(lines.first)
      read_at = Date.new(year, month, 1).end_of_month
      Well.create params.merge(read_at: read_at)
      puts "Saved #{params.inspect}"
    else
      puts "Couldn't find any records in #{month}/#{year}"
    end
    puts
  end
end

str = "Date,Oil total,Oil bpd,Gas total,Gas MCF/d,Water total,Water bpd\n"
Well.order('read_at ASC').each do |well|
  fields = [well.read_at.to_formatted_s(:db)]
  if well.days_in_operation > 0
    fields << well.oil << (well.oil / well.days_in_operation)
    fields << well.gas << (well.gas / well.days_in_operation)
    fields << well.water << (well.water / well.days_in_operation)
  else
    fields << well.oil << 0
    fields << well.gas << 0
    fields << well.water << 0
  end
  str += fields.join(',') + "\n"
end

puts str
File.open('oil.csv', 'w') { |f| f.puts str }
