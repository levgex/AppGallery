//
//  Collection+Extension.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import Foundation

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
