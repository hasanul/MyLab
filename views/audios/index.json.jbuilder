json.array!(@audios) do |audio|
  json.extract! audio, :user_id, :title, :desc, :path, :published, :featured, :hits
  json.url audio_url(audio, format: :json)
end
