//
//  ImageViewContainer.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

protocol ImageViewContainer {
    var rootView: UIView { get }
    var imageView: UIImageView { get }
}
