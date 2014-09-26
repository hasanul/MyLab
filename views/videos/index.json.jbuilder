json.array!(@plans) do |plan|
  json.extract! plan, :name, :desc, :is_free, :price, :period, :period_unit, :published
  json.url plan_url(plan, format: :json)
end
