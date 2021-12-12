# NOTE -- This doesn't work yet!

# Requirements:
#   brew install imagemagick
#   gem install gruff
#   gem install byebug

require 'byebug'
require 'csv'
require 'gruff'

begin

  block_production = CSV.read('solana-block-production-256.csv')
  # puts block_production[0].inspect
  # puts block_production[1].inspect

  # Collect the skip rates into a Hash
  skip_rates = block_production[1..block_production.length].collect{|b| b[3].to_f}
  # puts skip_rates[0].inspect
  # puts skip_rates[1].inspect

  # Create a hash for the labels
  labels = {}
  i = 0
  block_production[1..block_production.length].each do |block|
    labels[i] = block[0]
    # byebug
    i += 1
  end
  # puts labels.class
  # puts "0 => #{labels[0]}"
  # puts "1 => #{labels[1]}"
  # puts labels[1].inspect

  g = Gruff::Line.new
  g.title = 'Solana Epoch 256'
  g.labels = labels
  g.data :skip_rate, skip_rates
  # g.labels = { 0 => '5/6', 1 => '5/15', 2 => '5/24', 3 => '5/30', 4 => '6/4', 5 => '6/12', 6 => '6/21', 7 => '6/28' }
  # g.data :Jimmy, [25, 36, 86, 39, 25, 31, 79, 88]
  # g.data :Charles, [80, 54, 67, 54, 68, 70, 90, 95]

  g.write('solana-epoch-256.png')
rescue StandardError => e
  e.class
  e.message
  e.backtrace
end
