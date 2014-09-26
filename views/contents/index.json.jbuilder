json.array!(@contents) do |content|
  json.extract! content, :id, :title, :alias, :text, :published, :hits, :ordering
  json.url content_url(content, format: :json)
end
