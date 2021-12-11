# Start wih a JSON output file from the CLI
#
# solana block-production --epoch 256 --verbose --output json > ~/desktop/solana-block-production-256.json
#
# Then run this script. Adjust file names & path names as needed
#
# ruby ruby solana-block-production.rb

require 'csv'
require 'json'
require 'byebug'

input_file = 'solana-block-production-256.json'
output_file = 'solana-block-production-256.csv'
moving_avg_length = 200

# Read the
json = JSON.load(File.open(input_file))
skips = []

CSV.open(output_file, 'w') do |csv|
  csv << %w[slot leader skipped skip_rate]
  json['individual_slot_status'].each do |j|
    # Update the skips array
    skips.delete_at(0) if skips.length == moving_avg_length
    skips << j['skipped']

    # byebug
    skip_rate = if skips.length == moving_avg_length
      (skips.count(true)/skips.length.to_f)/(moving_avg_length/100.0)
    else
      nil
    end

    # Write to the CSV
    csv << [j['slot'], j['leader'], j['skipped'], skip_rate]
  end
end

# puts skips
puts skips.length
