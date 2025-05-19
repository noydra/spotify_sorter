# Spotify Playlist Sorter (Ruby)

This is a simple web application built with Ruby and Sinatra that allows users to sort their Spotify playlists by various criteria and save the sorted version as a new playlist.

## Features

*   **Spotify Authentication:** Securely log in with your Spotify account using OmniAuth.
*   **List Playlists:** View a list of your Spotify playlists.
*   **Sort Playlists:** Select a playlist and sort its tracks by:
    *   Album Cover (Note: Sorting by actual image content is not feasible; this likely sorts by a proxy like album release date or internal ID if the API provides a consistent image order for albums. If it sorts by URL, the order might not be meaningful.)
    *   Album Name
    *   Artist Name
    *   Track Name
*   **Create New Sorted Playlist:** A new playlist is created in your Spotify account with the sorted tracks. The new playlist will be named "[Original Playlist Name] - Sorted by [Sort Criteria]".
*   **Logout:** Securely log out of the application.

## Technologies Used

*   **Ruby:** The core programming language.
*   **Sinatra:** A DSL for quickly creating web applications in Ruby.
*   **RSpotify:** A Ruby wrapper for the Spotify Web API (though this project now primarily uses `rest-client` for direct API calls).
*   **OmniAuth (omniauth-spotify):** For handling Spotify OAuth2 authentication.
*   **rest-client:** For making HTTP requests to the Spotify API.
*   **HTML/ERB:** For the views.

## Setup and Installation

1.  **Clone the repository (or download the files):**
    ```bash
    # If it were a git repo
    # git clone <repository_url>
    # cd spotify_sorter_ruby
    ```
2.  **Install Ruby:** Ensure you have Ruby installed on your system. You can check with `ruby -v`.
3.  **Install Bundler:** If you don't have Bundler, install it:
    ```bash
    gem install bundler
    ```
4.  **Install Dependencies:** Navigate to the project directory and run:
    ```bash
    bundle install
    ```
5.  **Configure Spotify API Credentials:**
    *   Open the `app.rb` file.
    *   Locate the following lines:
        ```ruby
        spotify_client_id = 'YOUR_SPOTIFY_CLIENT_ID'
        spotify_client_secret = 'YOUR_SPOTIFY_CLIENT_SECRET'
        ```
    *   Replace `'YOUR_SPOTIFY_CLIENT_ID'` and `'YOUR_SPOTIFY_CLIENT_SECRET'` with your actual Spotify application Client ID and Client Secret.
        *   You can get these by creating an application on the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/).
        *   **Important:** When setting up your Spotify application, you **must** add `http://127.0.0.1:8888/callback` to the "Redirect URIs" in your application settings on the Spotify Developer Dashboard.

6.  **Run the Application:**
    ```bash
    ruby app.rb
    ```
7.  **Access the Application:** Open your web browser and go to `http://127.0.0.1:8888`.

## How It Works

1.  The user visits the homepage and is prompted to log in with Spotify.
2.  Upon successful authentication, the application fetches the user's playlists using the Spotify API.
3.  The user selects a playlist and a sorting criterion.
4.  The application fetches all tracks from the selected playlist.
5.  The tracks are sorted based on the chosen criterion.
6.  A new playlist is created in the user's Spotify account, and the sorted tracks are added to it.
7.  A confirmation message with a link to the new playlist is displayed.

## Notes

*   The application uses port `8888` by default. This is configured in `app.rb`.
*   Session data is stored server-side to manage user authentication.
*   Error handling is in place for common issues like API request failures or authentication problems.
