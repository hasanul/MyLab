json.array!(@states) do |state|
  json.extract! state, :country_id, :state_name, :state_3_code, :state_2_code, :published
  json.url state_url(state, format: :json)
end
