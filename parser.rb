require 'nokogiri'
require 'csv'

filename = ARGV[0]
if filename.nil?
  puts "Usage: ruby parser.rb filename_of_aktiawallet_summary.html"
  exit
end

def get_currency_from_total(s)
  match = /\-?\s?(\d+,\d\d)\s(\w{3})/.match(s)
  match[2]
end

def get_amount_from_total(s)
  match = /\-?\s?(\d+,\d\d)\s(\w{3})/.match(s)
  match[1]
end

def puts_transaction(transaction)

  arr = []

  arr << transaction.css('.header .span2').first.text.strip

  arr << transaction.css('.header .span8').first.text.strip

  total_s = transaction.css('.header .amount').first.text.strip
  arr << get_amount_from_total(total_s)
  arr << get_currency_from_total(total_s)

  details = transaction.css('.transaction-row .details .span6:nth-child(1) .row-fluid')

  arr << details.first.css('.span6:nth-child(2)').first.text.strip

  if details.size == 3
    arr << details[1].css('.span6:nth-child(2)').first.text.strip
  else
    arr << ""
  end

  arr << details.last.css('.span6:nth-child(2)').first.text.strip

  other_curr = transaction.css('.transaction-row .details > .span6:nth-child(2)')
  other_curr_value = other_curr.first.text.strip.gsub(/\t|\n/, '')

  unless other_curr_value.empty?
    total_s = other_curr.css('.row-fluid:nth-child(1) .span6:nth-child(2)').first.text.strip
    arr << get_amount_from_total(total_s)
    arr << get_currency_from_total(total_s)
  else
    arr << ""
    arr << ""
  end

  unless other_curr.first.text.strip.empty?
    arr << other_curr.css('.row-fluid:nth-child(2) .span6:nth-child(2)').first.text.strip
  else
    arr << ""
  end

  arr
rescue Exception => e
  puts "<<<"
  puts transaction
  puts "<<<"
  raise e
end

file = File.read(filename)
doc = Nokogiri::HTML(file)

CSV.open('aktiawallet.csv', 'w') do |csv|
  csv << [
    'Date',
    'Vendor',
    'Amount',
    'Currency',
    'Reference',
    'Location',
    'Transaction Date',
    'Original Amount',
    'Original Currency',
    'Exchange Rate'
  ]
  doc.css('.transaction').each do |transaction|
    csv << puts_transaction(transaction)
  end
end

