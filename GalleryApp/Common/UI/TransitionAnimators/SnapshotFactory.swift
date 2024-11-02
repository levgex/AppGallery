//
//  SnapshotFactory.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

class SnapshotFactory {
    static func makeSnapshot(frame: CGRect, image: UIImage, cornerRadius: CGFloat) -> UIImageView {
        let snapshot = UIImageView(frame: frame)
        snapshot.image = image
        snapshot.layer.cornerRadius = cornerRadius
        snapshot.clipsToBounds = true
        snapshot.contentMode = .scaleAspectFit

        return snapshot
    }
}
