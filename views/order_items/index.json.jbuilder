json.array!(@order_items) do |order_item|
  json.extract! order_item, :id, :order_id, :product_id, :product_name, :product_quantity, :product_item_price, :product_tax, :product_final_price, :order_status
  json.url order_item_url(order_item, format: :json)
end
