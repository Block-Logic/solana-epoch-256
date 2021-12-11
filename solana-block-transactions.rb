# ruby solana-block-transactions.rb 'RPC_ENDPOINT_URL'
#
# Ths script will loop through each slot in epoch 256, fetch the block from RPC
# and count the number of transactions inside the block.
#
# Requirements:
#   gem install 'byebug'
#   gem install 'solana_rpc_ruby'

require 'json'
require 'byebug'
require 'csv'
require 'solana_rpc_ruby'

mainnet_cluster = ARGV[0]
slot_start = 110592000
slot_end = 111023999

interrupted = false
trap('INT') { interrupted = true }

output_file = 'solana-block-transactions.csv'

SolanaRpcRuby.config do |c|
  c.json_rpc_version = '2.0'
  c.cluster = mainnet_cluster
end

method_wrapper = SolanaRpcRuby::MethodsWrapper.new(cluster: SolanaRpcRuby.cluster)

time_start = Time.now
begin
  CSV.open(output_file, 'w') do |csv|
    csv << %w[slot tx_count]
    counter = 0
    slot_start.upto(slot_start + 1001).each do |slot|
      begin
        block = method_wrapper.get_block(slot)
      rescue SolanaRpcRuby::ApiError => e
        # puts "#{slot}: #{e.message}"
        block = nil
      end

      tx_count = block.nil? ? 0 : block.result['transactions'].count

      # byebug
      puts "#{slot} #{tx_count}" if counter%1000 == 0
      csv << [slot, tx_count]
      counter += 1
      break if interrupted
    end
  end
rescue StandardError => e
  puts e.class
  puts e.message
  puts e.backtrace
end
time_end = Time.now
puts "  Time Start: #{time_start}"
puts "    Time End: #{time_end}"
puts "Time Elapsed: #{time_end - time_start}"
