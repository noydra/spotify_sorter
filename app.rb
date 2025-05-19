require 'sinatra'
require 'rspotify'
require 'omniauth'
require 'omniauth-spotify'
require 'securerandom'
require 'json'
require 'rest-client'


def get_env_var(key, default = nil)
  ENV[key] || default
end

configure do
  set :bind, '127.0.0.1'
  set :port, 8888 
  
  
  enable :sessions
  set :session_secret, SecureRandom.hex(64) 
  set :static, true
  set :public_folder, File.dirname(__FILE__) + '/public'
  set :views, File.dirname(__FILE__) + '/views'
  set :root, File.dirname(__FILE__)
end


OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true
  
spotify_client_id = 'a85cc8cab639467788723c124911dbd2'
spotify_client_secret = 'fef89bc7cb904349b3291011de317a52'

localhost_callback_url = 'http://127.0.0.1:8888/callback'

RSpotify.authenticate(spotify_client_id, spotify_client_secret)
RSpotify.raw_response = true 


use OmniAuth::Builder do
  provider :spotify, spotify_client_id, spotify_client_secret, 
           scope: 'playlist-modify-public playlist-read-private user-read-email user-library-read',
           callback_path: '/callback', 
           callback_url: localhost_callback_url, 
           provider_ignores_state: true 
end

get '/' do
  @playlists = []
  @user_name = nil
  
  if session[:auth_data]
    begin
      
      @user_name = session[:auth_data]['display_name']
      
      
      access_token = session[:auth_data]['token']
      
      
      if access_token
        
        headers = {
          'Authorization' => "Bearer #{access_token}",
          'Content-Type' => 'application/json'
        }
        
        response = RestClient.get('https://api.spotify.com/v1/me/playlists?limit=50', headers)
        playlists_data = JSON.parse(response.body)
        
        @playlists = playlists_data['items'].map do |playlist|
          {
            'id' => playlist['id'],
            'name' => playlist['name'],
            'tracks_total' => playlist['tracks']['total']
          }
        end
      end
    rescue => e
      puts "Playlist error: #{e.message}"
      puts e.backtrace
      session[:error] = "Could not retrieve your playlists: #{e.message}"
    end
  end
  
  erb :index
end

get '/callback' do
  begin
    auth = request.env['omniauth.auth']
    if auth.nil?
      puts "Auth is nil!"
      session[:error] = "Authentication failed: Could not retrieve authentication data"
      redirect '/'
      return
    end
    
    
    credentials = auth['credentials']
    info = auth['info']
    
    
    session[:auth_data] = {
      'id' => auth['uid'],
      'display_name' => info['name'],
      'email' => info['email'],
      'token' => credentials['token'],
      'refresh_token' => credentials['refresh_token']
    }
    
    # RSpotify::User.new RSpotify.authenticate 
    redirect '/'
  rescue => e
    puts "Callback error: #{e.message}"
    puts e.backtrace
    session[:error] = "Authentication failed: #{e.message}"
    redirect '/'
  end
end

get '/logout' do
  session.clear
  redirect '/'
end

# Spotify OmniAuth callback 
get '/auth/spotify/callback' do
  begin
    puts "Original Spotify callback received - forwarding..."
    auth = request.env['omniauth.auth']
    if auth
      session[:user] = RSpotify::User.new(auth)
      redirect '/'
    else
      redirect '/callback'
    end
  rescue => e
    puts "Auth/spotify/callback error: #{e.message}"
    puts e.backtrace
    session[:error] = "Authentication failed in original callback: #{e.message}"
    redirect '/'
  end
end


set :root, File.dirname(__FILE__)
set :public_folder, File.dirname(__FILE__) + '/public'
set :views, File.dirname(__FILE__) + '/views'

post '/sort_playlist' do
  begin

    auth_data = session[:auth_data]
    redirect '/' unless auth_data
    
    access_token = auth_data['token']
    user_id = auth_data['id']
    
    playlist_id = params[:playlist_id]
    sort_by = params[:sort_by]
    
    headers = {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }
    
 
    begin
   
      playlist_response = RestClient.get("https://api.spotify.com/v1/playlists/#{playlist_id}", headers)
      playlist_data = JSON.parse(playlist_response.body)
      playlist_name = playlist_data['name']
      
      tracks = []
      next_url = "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks?limit=100"
      
      while next_url
        tracks_response = RestClient.get(next_url, headers)
        tracks_data = JSON.parse(tracks_response.body)
        
        tracks += tracks_data['items'].map { |item| item['track'] }
        
        next_url = tracks_data['next']
      end
      
      if tracks.empty?
        session[:error] = "The selected playlist has no tracks to sort."
        redirect '/'
      end

      sorted_tracks = case sort_by
      when "album_cover"
        tracks.sort_by { |t| t.dig('album', 'images', 0, 'url') || "" }
      when "album_name"
        tracks.sort_by { |t| t.dig('album', 'name').to_s.downcase }
      when "artist_name"
        tracks.sort_by { |t| t.dig('artists', 0, 'name').to_s.downcase }
      when "track_name"
        tracks.sort_by { |t| t['name'].to_s.downcase }
      else
        tracks
      end

      sort_method = case sort_by
        when "album_cover" then "Album Cover"
        when "album_name" then "Album Name"
        when "artist_name" then "Artist Name"
        when "track_name" then "Track Name"
        else "Custom Order"
      end
      
      new_playlist_name = "#{playlist_name} - Sorted by #{sort_method}"
      
      create_playlist_payload = {
        name: new_playlist_name,
        public: true,
        description: "Sorted version of #{playlist_name} by #{sort_method}"
      }
      
      new_playlist_response = RestClient.post(
        "https://api.spotify.com/v1/users/#{user_id}/playlists",
        create_playlist_payload.to_json,
        headers
      )
      
      new_playlist = JSON.parse(new_playlist_response.body)
      new_playlist_id = new_playlist['id']
      
      sorted_tracks.each_slice(100) do |track_batch|
        track_uris = track_batch.map { |t| t['uri'] }
        
        add_tracks_payload = { uris: track_uris }
        
        RestClient.post(
          "https://api.spotify.com/v1/playlists/#{new_playlist_id}/tracks",
          add_tracks_payload.to_json,
          headers
        )
      end
      
      @original_playlist_name = playlist_name
      @sort_method = sort_method
      @new_playlist_name = new_playlist_name
      @track_count = tracks.count
      @new_playlist_url = new_playlist['external_urls']['spotify']
      
      erb :result
    rescue => e
      puts "Error sorting playlist: #{e.message}"
      puts e.backtrace
      session[:error] = "Error sorting playlist: #{e.message}"
      redirect '/'
    end
  rescue => e
    puts "Unexpected error: #{e.message}"
    puts e.backtrace
    session[:error] = "An unexpected error occurred: #{e.message}"
    redirect '/'
  end
end
