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
    :TotalAmount => 1000,
    :TradeDesc => "tradedesc",
    :ItemName => "屁孩章嘉的屁孩哈特佛",
    :ReturnURL => "http://localhost:4567/",
    :ClientBackURL => "http://localhost:4567/",
    :ChoosePayment => 'Credit',
    :InvoiceMark => "Y",
    :RelateNumber => trade_no,
    :CustomerID => "",
    :CustomerIdentifier => "",
    :CustomerName => "屁孩華夏",
    :CustomerAddr => "",
    :CustomerPhone => "",
    :CustomerEmail => "bird.chiu@sun-innovation.com",
    :ClearanceMark => "",
    :TaxType => "1",
    :CarruerType => "",
    :CarruerNum => "",
    :Donation => "2",
    :LoveCode => "",
    :Print => "0",
    :InvoiceItemName => "屁孩章嘉的屁孩哈特佛",
    :InvoiceItemCount => "1",
    :InvoiceItemWord => "個",
    :InvoiceItemPrice => 1000,
    :InvoiceItemTaxType => "1",
    :InvoiceRemark => "1",
    :DelayDay => "0",
    :InvType => "05"
  })

  erb :index
end