//
//  GalleryGridLayout.swift
//  GalleryApp
//
//  Created by evgeniy.lebedev on 01.11.2024.
//

import UIKit

class GalleryGridLayout: UICollectionViewLayout {

    private enum Constants {
        static let numberOfColumns = 3
        static let numberOfColumnsLandscape = 5

        static let footerHeight = 48.0
    }

    // MARK: - Properties

    var photos: [[Photo]] = []

    // MARK: - Private properties

    private var cache = [IndexPath: UICollectionViewLayoutAttributes]()
    private var contentHeight: CGFloat = 0
    private var cellPadding: CGFloat = 8

    private var footerAttributes: UICollectionViewLayoutAttributes?

    private var contentWidth: CGFloat {
        guard let collectionView = self.collectionView else {
            return 0
        }
        return collectionView.bounds.width
    }

    private var numberOfColumns: Int {
        guard let collectionView = self.collectionView else {
            return 0
        }
        let isLandscape = collectionView.bounds.width > collectionView.bounds.height
        return isLandscape ? Constants.numberOfColumnsLandscape : Constants.numberOfColumns
    }

    // MARK: - Override methods

    override func prepare() {
        guard
            self.cache.isEmpty,
            let collectionView = self.collectionView
        else { return }

        let numberOfColumns = self.numberOfColumns

        let columnWidth = self.contentWidth / CGFloat(numberOfColumns)
        let cellWidth = columnWidth - self.cellPadding

        let xColumnOffset: [CGFloat] = (0..<numberOfColumns).map({ CGFloat($0) * columnWidth })
        var yColumnOffset: [CGFloat] = Array(repeating: 0, count: numberOfColumns)

        for section in 0..<collectionView.numberOfSections {
            for item in 0..<collectionView.numberOfItems(inSection: section) {
                self.prepareItemWith(indexPath: IndexPath(item: item, section: section), cellWidth: cellWidth, xColumnOffset: xColumnOffset, yColumnOffset: &yColumnOffset)
            }
        }

        self.footerAttributes = self.layoutAttributesForFooter()
        self.contentHeight += self.footerAttributes?.size.height ?? 0
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleAttributes = cache.values.filter { $0.frame.intersects(rect) }
        if !visibleAttributes.isEmpty,
            let footerAttributes = footerAttributes, footerAttributes.frame.intersects(rect) {
            visibleAttributes.append(footerAttributes)
        }

        return visibleAttributes
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == UICollectionView.elementKindSectionFooter {
            return footerAttributes
        }
        return nil
    }

    override func invalidateLayout() {
        super.invalidateLayout()

        self.cache.removeAll()
        self.contentHeight = 0
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath]
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return self.collectionView?.bounds.size != newBounds.size
    }

    // MARK: - Private methods

    private func prepareItemWith(indexPath: IndexPath, cellWidth: CGFloat, xColumnOffset: [CGFloat], yColumnOffset: inout [CGFloat]) {
        let aspectRatio = self.aspectRatioForPhoto(photos[safe: indexPath.section]?[safe: indexPath.item])
        let cellHeight = cellWidth * aspectRatio

        let shortestColumnIndex = yColumnOffset.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
        let leftInset = self.cellPadding * 0.5

        let cellFrame = CGRect(x: leftInset + xColumnOffset[shortestColumnIndex], y: self.cellPadding + yColumnOffset[shortestColumnIndex], width: cellWidth, height: cellHeight)
        self.cache[indexPath] = self.makeLayoutAttributesWith(indexPath: indexPath, frame: cellFrame)

        yColumnOffset[shortestColumnIndex] += cellHeight + self.cellPadding
        self.contentHeight = max(self.contentHeight, yColumnOffset[shortestColumnIndex])
    }

    private func layoutAttributesForFooter() -> UICollectionViewLayoutAttributes {
        let footerIndexPath = IndexPath(item: 0, section: 0)
        let footerAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: footerIndexPath)
        let footerHeight = Constants.footerHeight
        footerAttributes.frame = CGRect(x: 0, y: self.contentHeight, width: self.collectionView?.bounds.width ?? 0, height: footerHeight)
        return footerAttributes
    }

    private func makeLayoutAttributesWith(indexPath: IndexPath, frame: CGRect) -> UICollectionViewLayoutAttributes {
        let item = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        item.frame = frame
        return item
    }

    private func aspectRatioForPhoto(_ photo: Photo?) -> CGFloat {
        guard let photo else { return 1 }
        return CGFloat(photo.height) / CGFloat(photo.width)
    }
}
