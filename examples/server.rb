# encoding: UTF-8
$: << File.expand_path('../../lib', __FILE__)
require 'bundler/setup'
require 'sinatra'
require 'allpay'

get '/' do
  client = Allpay::Client.new(mode: :test)
  @params = client.generate_checkout_params({
    :MerchantTradeNo => SecureRandom.hex(4),
    :TotalAmount => 1000,
    :TradeDesc => "tradedesc",
    :ItemName => "itemname超強的",
    :ReturnURL => "http://localhost:4567/",
    :ClientBackURL => "http://localhost:4567/",
    :ChoosePayment => 'Credit',
    :InvoiceMark => "Y",
    :RelateNumber => SecureRandom.hex(4),
    :CustomerID => "",
    :CustomerIdentifier => "",
    :CustomerName => "屁孩章嘉",
    :CustomerAddr => "",
    :CustomerPhone => "",
    :CustomerEmail => "屁孩章嘉ghawhicomte",
    :ClearanceMark => "",
    :TaxType => "1",
    :CarruerType => "",
    :CarruerNum => "",
    :Donation => "2",
    :LoveCode => "",
    :Print => "0",
    :InvoiceItemName => "itemname超強的",
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