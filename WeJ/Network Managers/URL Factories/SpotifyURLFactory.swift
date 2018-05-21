//
//  SpotifyURLFactory.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 7/27/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation

struct SpotifyURLFactory {

    private static let baseSpotifyWebAPI = "api.spotify.com"
    
    static func createSearchRequest(forTerm term: String) -> URLRequest {
        let disallowedChars = CharacterSet(charactersIn: "()[],.!?")
        let escapedTerm = term.components(separatedBy: disallowedChars).joined(separator: " ").replacedWhiteSpaceForURL
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/search"
        
        let urlParameters = ["q": escapedTerm,
                             "type": "track"]
        var queryItems = [URLQueryItem]()
        for (key, value) in urlParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        urlComponents.queryItems = queryItems
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(Party.cookie!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createTrackRequest(forID id: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/tracks/\(id.components(separatedBy: ":")[1])"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(Party.cookie!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createLibraryAlbumsRequest(atOffset offset: Int) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/me/albums"
        
        let urlParameters = ["limit": "50",
                             "offset": String(offset)]
        var queryItems = [URLQueryItem]()
        for (key, value) in urlParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        urlComponents.queryItems = queryItems
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(SpotifyAuthorizationManager.getAuth().session.accessToken!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createLibraryAlbumsTracksRequest(atOffset offset: Int, forID id: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/albums/\(id)/tracks"
        
        let urlParameters = ["limit": "50",
                             "offset": String(offset)]
        var queryItems = [URLQueryItem]()
        for (key, value) in urlParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        urlComponents.queryItems = queryItems
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(SpotifyAuthorizationManager.getAuth().session.accessToken!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createLibraryPlaylistsRequest() -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/me/playlists"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(SpotifyAuthorizationManager.getAuth().session.accessToken!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createLibraryPlaylistTracksRequest(atOffset offset: Int, forOwnerID ownerID: String, forPlaylistID playlistID: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/users/\(ownerID)/playlists/\(playlistID)/tracks"
        
        let urlParameters = ["limit": "50",
                             "offset": String(offset)]
        var queryItems = [URLQueryItem]()
        for (key, value) in urlParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        urlComponents.queryItems = queryItems
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(SpotifyAuthorizationManager.getAuth().session.accessToken!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createLibraryTracksRequest(atOffset offset: Int) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/me/tracks"
        
        let urlParameters = ["limit": "50",
                             "offset": String(offset)]
        var queryItems = [URLQueryItem]()
        for (key, value) in urlParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        urlComponents.queryItems = queryItems
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(SpotifyAuthorizationManager.getAuth().session.accessToken!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createPlaylistsRequest(forOwnerID ownerID: String, forPlaylistID playlistID: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/users/\(ownerID)/playlists/\(playlistID)"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(Party.cookie!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createPlaylistsIDRequest(forCategoryID categoryID: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/browse/categories/\(categoryID)/playlists"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(Party.cookie!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
}
