//
//  Photo.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import Foundation

struct Photo: Codable {

    struct Source: Codable {
        let small: String
        let medium: String
        let large: String
        let original: String
    }

    let id: Int
    let width: Int
    let height: Int
    let url: String
    let photographer: String
    let src: Source

}
