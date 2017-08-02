//
//  Song.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation

class Track: NSObject {
    var id = String()
    var name = String()
    var artist = String()
    var album = String()
    
    var lowResArtworkURL = String()
    var lowResArtwork: UIImage?
    
    var mediumResArtworkURL: String?
    var mediumResArtwork: UIImage?
    
    var highResArtworkURL = String()
    var highResArtwork: UIImage?
    
    var length: TimeInterval?
    
    static func typeOf(track: String) -> TrackType {
        if track.hasPrefix("S:") {
            return .service(ofType: .spotify)
        } else if track.hasPrefix("A:") {
            return .service(ofType: .appleMusic)
        } else if track.hasPrefix("R:") {
            return .removal
        } else {
            return .none
        }
    }
    
    static func fetchImage(fromURL urlString: String) -> UIImage? {
        if let url = URL(string: urlString) {
            do {
                let data = try Data(contentsOf: url)
                return UIImage(data: data)
            } catch {
                print("Error trying to get data from Artwork URL")
            }
        }
        return nil
    }
}
