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

# A quick support method to parse a string between two tokens
module TXSupport
  def between(input, start_token = '[B]', end_token = '[E]', start_position = 0)
    # The REGEX version of this was choking on javascript & html in the string:
    # st = Regexp.escape(start_token)
    # et = Regexp.escape(end_token)
    # /#{st}.+#{et}/.match("BOS#{s}EOS")[0].sub(start_token, '').sub(end_token, '').strip rescue nil
    # So, I am doing this instead:
    s = "[B]#{input}[E]"
    start_token = '[B]' if start_token == ''
    end_token = '[E]'   if end_token == ''
    return nil if !start_token.is_a?(String) || !end_token.is_a?(String)
    return nil if !s.include?(start_token) || !s.include?(end_token)
    tsi = s.index(start_token, start_position) + start_token.length
    tei = s.index(end_token, tsi) - 1
    s[tsi..tei].strip
  rescue NoMethodError
    nil
  end
end
include TXSupport

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
    csv << %w[slot tx_count compute_units]
    counter = 0
    slot_start.upto(slot_end).each do |slot|
      compute_units = 0
      begin
        block = method_wrapper.get_block(slot)
      rescue SolanaRpcRuby::ApiError => e
        # puts "#{slot}: #{e.message}"
        block = nil
      end

      if block.nil?
        tx_count = 0
        # compute_units = 0
      else
        tx_count = block.result['transactions'].count
        if tx_count > 0
          block.result['transactions'].each do |tx|
            # byebug
            # "Program ... consumed 19685 of 200000 compute units"
            log_message = tx['meta']['logMessages'].select{|l| l.include?('compute units')}
            compute_units += between(log_message, 'consumed', 'of').to_i
            break if interrupted
          end
        end
      end

      # byebug
      puts "#{slot}, #{tx_count}, #{compute_units}" if counter%1000 == 0
      csv << [slot, tx_count, compute_units]
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
