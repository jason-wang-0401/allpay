require 'net/http'
require 'json'
require 'cgi'
require 'digest'
require 'allpay/errors'
require 'allpay/core_ext/hash'

module Allpay
  class Invoice
    PRE_ENCODE_COLUMN = [:CustomerName, :CustomerAddr , :CustomerEmail, :ItemName, :ItemWord, :InvoiceRemark, :InvCreateDate]
    BLACK_LIST_COLUMN = [:ItemName, :ItemWord, :InvoiceRemark]
    PRODUCTION_API_HOST = 'https://einvoice.allpay.com.tw/Invoice'.freeze
    TEST_API_HOST = 'http://einvoice-stage.allpay.com.tw/Invoice'.freeze
    TEST_OPTIONS = {
      merchant_id: '2000132',
      hash_key: 'ejCk326UnaZWKisg',
      hash_iv: 'q9jcZX8Ib9LM8wYk'
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
      hash = pre_encode(params.clone)
      raw = hash.sort_by{|x| x.to_s.downcase}.map!{ |k,v| "#{k}=#{v}"}.join('&')
      padded = "HashKey=#{@options[:hash_key]}&#{raw}&HashIV=#{@options[:hash_iv]}"
      url_encoded = CGI::escape(padded).downcase!
      Digest::MD5.hexdigest(url_encoded).upcase!
    end

    def verify_mac params = {}
      stringified_keys = params.stringify_keys
      check_mac_value = stringified_keys.delete('CheckMacValue')
      make_mac(stringified_keys) == check_mac_value
    end

    def generate_params overwrite_params = {}
      # mac = make_mac(result.clone.delete_if{|key,value| [:ItemName,:ItemWord,:InvoiceRemark].find_index(key)})
      result = overwrite_params
      result[:TimeStamp] = Time.now.to_i
      result[:MerchantID] = @options[:merchant_id]
      result[:CheckMacValue] = make_mac(result)
      result
    end

    def request path, params = {}
      api_url = URI.parse(api_host + path)
      Net::HTTP.post_form api_url, params
    end

    # 一般開立發票API
    # url_encode => Reason
    # 在產生 CheckMacValue 時,須將 ItemName、ItemWord 及 InvoiceRemark 等欄位排除
    def issue overwrite_params = {}
      res = request '/Issue' , generate_params(overwrite_params)
      Hash[res.body.split('&').map!{|i| i.split('=')}]
    end

    # 延遲或觸發開立發票API
    # url_encode => Reason
    # 在產生 CheckMacValue 時,須將 ItemName、ItemWord 及 InvoiceRemark 等欄位排除
    def delay_issue overwrite_params = {}
      res = request '/DelayIssue' , overwrite_params
      Hash[res.body.split('&').map!{|i| i.split('=')}]
    end

    # 開立折讓API
    # url_encode => Reason
    # 在產生 CheckMacValue 時,須將 ItemName 及 ItemWord 等欄位排除
    def allowance
      res = request '/DelayIssue' , overwrite_params
      Hash[res.body.split('&').map!{|i| i.split('=')}]      
    end

    # 發票作廢API
    # url_encode => Reason
    # 在產生 CheckMacValue 時,須將 Reason 欄位排除
    def issue_invalid
      res = request '/DelayIssue' , overwrite_params
      Hash[res.body.split('&').map!{|i| i.split('=')}]      
    end

    # 折讓作廢API
    # url_encode => Reason
    # 在產生 CheckMacValue 時,須將 ItemName 及 ItemWord 等欄位排除    
    def allowance_invalid
      res = request '/DelayIssue' , overwrite_params
      Hash[res.body.split('&').map!{|i| i.split('=')}]     
    end

    # 查詢發票API
    # url_encode => IIS_Customer_Name / IIS_Customer_Addr / ItemName / ItemWord / InvoiceRemark
    # 在產生 CheckMacValue 時,須將 ItemName、ItemWord 及 InvoiceRemark 等欄位排除
    def query_issue
      
    end

    # 查詢作廢發票API
    # url_encode => Reason
    # 在產生 CheckMacValue 時,須將 Reason 等欄位排除    
    def query_issue_invalid
      
    end

    # 查詢折讓明細API
    # url_encode => ItemName / ItemWord / IIS_Customer_Name
    # 在產生 CheckMacValue 時,須將 ItemName、ItemWord 等欄位排除    
    def query_allowance
      
    end

    # 查詢折讓作廢明細API
    # url_encode => Reason
    # 在產生 CheckMacValue 時,須將 Reason 等欄位排除    
    def query_allowance_invalid
      
    end

    # 發送通知API
    def invoice_notify
      res = request '/DelayIssue' , overwrite_params
      Hash[res.body.split('&').map!{|i| i.split('=')}]      
    end

    # 付款完成觸發或延遲開立發票API
    def trigger_issue
      res = request '/DelayIssue' , overwrite_params
      Hash[res.body.split('&').map!{|i| i.split('=')}]      
    end

    private

    def pre_encode params
      PRE_ENCODE_COLUMN.each do |key|
        params[key] = url_encode(params[key]) if params.has_key?(key)
      end
      params.delete_if{|key,value| BLACK_LIST_COLUMN.find_index(key)}
    end

    def option_required! *option_names
      option_names.each do |option_name|
        raise MissingOption, %Q{option "#{option_name}" is required.} if @options[option_name].nil?
      end
    end
  end
end
