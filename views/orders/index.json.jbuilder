json.array!(@orders) do |order|
  json.extract! order, :id, :user_id, :order_number, :order_subtotal, :order_tax, :order_total, :order_status, :customer_note, :ip_address
  json.url order_url(order, format: :json)
end
