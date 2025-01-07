using HTTP
using JSON
using Genie
using Genie.Router
using StatsBase

function get_spotify_token(client_id::String, client_secret::String)
    url = "https://accounts.spotify.com/api/token"
    headers = ["Authorization" => "Basic " * base64encode("$client_id:$client_secret")]
    body = Dict("grant_type" => "client_credentials")

    response = HTTP.post(url, headers; body=body)
    token_data = JSON.parse(String(response.body))
    return token_data["access_token"]
end

# Функция для получения аудиофич треков
function get_track_features(track_ids::Vector{String}, token::String)
    url = "https://api.spotify.com/v1/audio-features"
    headers = ["Authorization" => "Bearer $token"]

    features = []
    for track_id in track_ids
        response = HTTP.get("$url/$track_id", headers=headers)
        push!(features, JSON.parse(String(response.body)))
    end
    return features
end


function analyze_taste(features::Vector{Dict})
    danceability = [f["danceability"] for f in features]
    energy = [f["energy"] for f in features]
    valence = [f["valence"] for f in features]

    results = Dict(
        "danceability" => mean(danceability),
        "energy" => mean(energy),
        "valence" => mean(valence)
    )
    return results
end

route("/analyze", method = POST) do
    request_data = JSON.parse(Genie.Requests.body())
    client_id = request_data["client_id"]
    client_secret = request_data["client_secret"]
    track_ids = request_data["track_ids"]

    token = get_spotify_token(client_id, client_secret)
    features = get_track_features(track_ids, token)
    results = analyze_taste(features)

    return Genie.Responses.json(results)
end

# Запуск сервера
Genie.config.server_host = "0.0.0.0"
Genie.config.server_port = 8080
Genie.startup()
