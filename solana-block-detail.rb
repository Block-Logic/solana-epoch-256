# ruby solana-block-detail.rb 'RPC_ENDPOINT_URL' slot_number
#
# Requirements:
#   gem install 'byebug'
#   gem install 'solana_rpc_ruby'

require 'byebug'
require 'csv'
require 'solana_rpc_ruby'

mainnet_cluster = ARGV[0]
slot_number = ARGV[1].to_i

interrupted = false
trap('INT') { interrupted = true }

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

SolanaRpcRuby.config do |c|
  c.json_rpc_version = '2.0'
  c.cluster = mainnet_cluster
end

method_wrapper = SolanaRpcRuby::MethodsWrapper.new(cluster: SolanaRpcRuby.cluster)

begin
  block = method_wrapper.get_block(slot_number)
  # puts block.inspect
  program_stats = {}
  compute_units_total = 0
  transactions_total = 0
  votes_total = 0
  block.result['transactions'].each do |tx|
    # puts tx.inspect
    # puts ''
    # byebug
    # "Program Vote111111111111111111111111111111111111111 invoke [1]"
    vote_message = nil
    vote_message = tx['meta']['logMessages'].select{|l| l.include?('Program Vote111111111111111111111111111111111111111 invoke')}
    # puts vote_message
    votes_total += 1 unless vote_message.empty?

    # "Program ... consumed 19685 of 200000 compute units"
    log_messages = tx['meta']['logMessages'].select{|l| l.include?('compute units')}
    # byebug if log_message.length > 1

    log_messages.each do |lm|
      program_id = between(lm, 'Program', 'consumed')
      compute_units = between(lm, 'consumed', 'of').to_i
      if compute_units > 0
        program_stats[program_id] = {tx_count: 0, compute_units: 0, avg_cu: 0} \
          if program_stats[program_id].nil?

        compute_units_total += compute_units
        transactions_total += 1

        program_stats[program_id][:tx_count] = program_stats[program_id][:tx_count] += 1
        program_stats[program_id][:compute_units] = program_stats[program_id][:compute_units] + compute_units
        program_stats[program_id][:avg_cu] = program_stats[program_id][:compute_units] / program_stats[program_id][:tx_count]
      end
      # puts "#{program_id} => #{compute_units}"
    end

    break if interrupted
  end

  # puts program_stats.inspect
  CSV.open("solana-block-summary-#{slot_number}.csv", 'w') do |csv|
    csv << %w[program invoke_count compute_units avg_cu]
    program_stats.each do |k,v|
      csv << [k, v[:tx_count], v[:compute_units], v[:avg_cu]]
    end
    csv << ['Total Non-Vote Invokes', transactions_total, compute_units_total, compute_units_total/transactions_total]
    csv << ['Total Votes', votes_total, nil, nil]
    csv << ['Total Invokes & Votes', transactions_total+votes_total, nil, nil]
  end

rescue StandardError => e
  puts e.class
  puts e.message
  puts e.backtrace
end
