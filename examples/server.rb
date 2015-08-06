# encoding: UTF-8
$: << File.expand_path('../../lib', __FILE__)
require 'bundler/setup'
require 'sinatra'
require 'allpay'

get '/' do
  client = Allpay::Client.new(mode: :test)
  trade_no = SecureRandom.hex(6)
  @params = client.generate_checkout_params({
                                              :MerchantTradeNo => trade_no,
                                              :TotalAmount => 123123,
                                              :TradeDesc => "屁孩章嘉的屁孩哈特佛",
                                              :ItemName => "屁孩章嘉的屁孩哈特佛",
                                              :ReturnURL => 'http://localhost:4567/',
                                              :ClientBackURL => 'http://localhost:4567/',
                                              :ChoosePayment => 'ALL',
                                              :InvoiceMark => 'Y',
                                              :RelateNumber => trade_no,
                                              :CustomerID => '',
                                              :CustomerIdentifier => '',
                                              :CustomerName => '屁孩章嘉的屁孩哈特佛',
                                              :CustomerAddr => '',
                                              :CustomerPhone => '',
                                              :CustomerEmail => 'fewfew@iofjoa.com',
                                              :ClearanceMark => '',
                                              :TaxType => '1',
                                              :CarruerType => '',
                                              :CarruerNum => '',
                                              :Donation => '2',
                                              :LoveCode => '',
                                              :Print => '0',
                                              :InvoiceItemName => '屁孩章嘉的屁孩哈特佛',
                                              :InvoiceItemCount => '1',
                                              :InvoiceItemWord => 'piece',
                                              :InvoiceItemPrice => 123123,
                                              :InvoiceItemTaxType => '1',
                                              :InvoiceRemark => '1',
                                              :DelayDay => '0',
                                              :InvType => '05',
                                              :PeriodAmount => 123123,      # 每次授權金額
                     :PeriodType => 'M',                  # 週期種類
                     :Frequency => 12,                      # 執行頻率(一年幾次)
                     :ExecTimes => 99,                      # 總共執行幾次
                     :PeriodReturnURL => 'http://localhost:4567/'
  })
  p "#{client.verify_mac(@params)}"
    erb :index
end
