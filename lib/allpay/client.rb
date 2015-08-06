# encoding: UTF-8
require 'net/http'
require 'json'
require 'cgi'
require 'digest'
require 'allpay/errors'
require 'allpay/core_ext/hash'

module Allpay
  class Client
    PRE_ENCODE_COLUMN = [:CustomerName, :CustomerAddr , :CustomerEmail, :InvoiceItemName, :InvoiceItemWord, :InvoiceRemark]
    PRODUCTION_API_HOST = 'https://payment.allpay.com.tw'.freeze
    TEST_API_HOST = 'http://payment-stage.allpay.com.tw'.freeze
    TEST_OPTIONS = {
      merchant_id: '2000132',
      hash_key: '5294y06JbISpM5x9',
      hash_iv: 'v77hoKGq4kWxNNIS'
    }.freeze

    attr_reader :options

    def initialize options = {}
      @options = {mode: :production}.merge!(options)
      case @options[:mode]
      when :production
        option_required! :merchant_id, :hash_key, :hash_iv
      when :test
        @options = TEST_OPTIONS.merge(options)
      else
        raise InvalidMode, %Q{option :mode is either :test or :production}
      end
      @options.freeze
    end

    def api_host
      case @options[:mode]
      when :production then PRODUCTION_API_HOST
      when :test then TEST_API_HOST
      end
    end

    def make_mac params = {}
      raw = pre_encode(params).sort_by{|x| x.to_s.downcase}.map!{|k,v| "#{k}=#{v}"}.join('&')
      padded = "HashKey=#{@options[:hash_key]}&#{raw}&HashIV=#{@options[:hash_iv]}"
      url_encoded = url_encode(padded).downcase!
      Digest::MD5.hexdigest(url_encoded).upcase!
    end

    #base from CGI::escape
    #replace (,),!,*,.,-,_ 
    def url_encode text 
      text = text.dup
      text.gsub!(/([^ a-zA-Z0-9\(\)\!\*_.-]+)/) do
        '%' + $1.unpack('H2' * $1.bytesize).join('%')
      end
      text.tr!(' ', '+')
      text
    end

    def verify_mac params = {}
      stringified_keys = params.stringify_keys
      check_mac_value = stringified_keys.delete('CheckMacValue')
      p "傳來的params #{stringified_keys}"
      p "傳來的mac #{check_mac_value}"
      p "驗證的mac #{make_mac(stringified_keys)}"
      make_mac(stringified_keys) == check_mac_value
    end

    def generate_params overwrite_params = {}
      result = overwrite_params.clone
      result[:MerchantID] = @options[:merchant_id]
      result[:CheckMacValue] = make_mac(result)
      result
    end

    def generate_checkout_params overwrite_params = {}
      generate_params({
        MerchantTradeDate: Time.now.strftime('%Y/%m/%d %H:%M:%S'),
        MerchantTradeNo: SecureRandom.hex(4),
        PaymentType: 'aio'
      }.merge!(overwrite_params))
    end

    def request path, params = {}
      api_url = URI.join(api_host, path)
      Net::HTTP.post_form api_url, generate_params(params)
    end

    def query_trade_info merchant_trade_number, platform = nil
      params = {
        MerchantTradeNo: merchant_trade_number,
        TimeStamp: Time.now.to_i,
        PlatformID: platform
      }
      params.delete_if{ |k, v| v.nil? }
      res = request '/Cashier/QueryTradeInfo', params
      Hash[res.body.split('&').map!{|i| i.split('=')}]
    end

    def query_period_credit_card_trade_info merchant_trade_number
      res = request '/Cashier/QueryPeriodCreditCardTradeInfo',
              MerchantTradeNo: merchant_trade_number,
              TimeStamp: Time.now.to_i
      JSON.parse(res.body)
    end

    def credit_do_action params = {}
      res = request '/CreditDetail/DoAction', params
      Hash[res.body.split('&').map!{|i| i.split('=')}]      
    end

    def aio_charge_back params = {}
      res = request '/Cashier/AioChargeback', params
      res.body
    end

    def capture params = {}
      res = request '/Cashier/Capture', params
      Hash[res.body.split('&').map!{|i| i.split('=')}]        
    end

    def gen_check_mac_value params = {}
      url = URI.join(api_host, '/AioHelper/GenCheckMacValue')
      res = Net::HTTP.post_form url, params
      res.body
    end

    private

    def pre_encode params
      PRE_ENCODE_COLUMN.each do |key|
        params[key] = url_encode(params[key]) if params.has_key?(key)
      end
      params
    end

    def option_required! *option_names
      option_names.each do |option_name|
        raise MissingOption, %Q{option "#{option_name}" is required.} if @options[option_name].nil?
      end
    end
  end
end
