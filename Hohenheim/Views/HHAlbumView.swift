//
//  HHAlbumView.swift
//  Hohenheim
//
//  Created by Elias Abel on 2015/11/14.
//  Copyright © 2015 Meniny Lab. All rights reserved.
//

import UIKit
import Photos

public protocol HHAlbumViewDelegate: class {
    func albumViewCameraRollUnauthorized()
    func albumViewCameraRollAuthorized()
}

final class HHAlbumView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, PHPhotoLibraryChangeObserver, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewConstraintHeight: NSLayoutConstraint!

    weak var delegate: HHAlbumViewDelegate? = nil
    var allowMultipleSelection = false
    
    fileprivate var assets: PHFetchResult<PHAsset>?
    fileprivate var imageManager: PHCachingImageManager?
    fileprivate var previousPreheatRect: CGRect = .zero
    fileprivate let cellSize = CGSize(width: 100, height: 100)
    
    var phAsset: PHAsset!
    var selectedAssets: [PHAsset] = []

    private let collectionViewOriginalConstraintTop: CGFloat = 50
    private var imaginaryCollectionViewOffsetStartPosY: CGFloat = 0.0
    
    static func instance() -> HHAlbumView {
        return UINib(nibName: "HHAlbumView", bundle: Bundle(for: self.classForCoder())).instantiate(withOwner: self, options: nil)[0] as! HHAlbumView
    }
    
    func initialize() {
        
        if self.assets != nil {
            return
        }
		
		self.isHidden = false
        
        collectionViewConstraintHeight.constant = self.frame.height - collectionViewOriginalConstraintTop
        collectionView.register(UINib(nibName: "HHAlbumViewCell", bundle: Bundle(for: self.classForCoder)), forCellWithReuseIdentifier: "HHAlbumViewCell")
		collectionView.backgroundColor = HohenheimConfiguration.backgroundColor
        collectionView.allowsMultipleSelection = allowMultipleSelection
        
        // Never load photos Unless the user allows to access to photo album
        checkPhotoAuth()
        
        // Sorting condition
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        let theAssets = PHAsset.fetchAssets(with: options)
        self.assets = theAssets
//        images = PHAsset.fetchAssets(with: .image, options: options)
        
        if theAssets.count > 0 {
            changeImage(theAssets[0])
            collectionView.reloadData()
            collectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: UICollectionViewScrollPosition())
        }
        
        PHPhotoLibrary.shared().register(self)
        
    }
    
    deinit {
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
    
    // MARK: - UICollectionViewDelegate Protocol
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HHAlbumViewCell", for: indexPath) as! HHAlbumViewCell
        
        let currentTag = cell.tag + 1
        cell.tag = currentTag
        
        if let collection = self.assets {
            if collection.count > 0 {
                let asset = collection[indexPath.item]
                switch asset.mediaType {
                case .unknown, .audio:
                    cell.image = nil
                    cell.infoLabel.text = nil
                    break
                default:
                    if asset.mediaType == .video {
                        cell.infoLabel.text = asset.duration.format()
                    } else {
                        cell.infoLabel.text = nil
                    }
                    self.imageManager?.requestImage(for: asset, targetSize: cellSize, contentMode: .aspectFill, options: nil) { result, info in
                        if cell.tag == currentTag {
                            cell.image = result
                        }
                    }
                    break
                }
                return cell
            }
        }
        cell.image = nil
        cell.infoLabel.text = nil
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.assets?.count ?? 0
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 3) / 4
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let asset = self.assets?[indexPath.row] {
            changeImage(asset)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if let asset = self.assets?[indexPath.row] {
            let selectedItem = self.selectedAssets.filter { $0 == asset }.first
            if let selected = selectedItem, let index = self.selectedAssets.index(of: selected) {
                self.selectedAssets.remove(at: index)
            }
        }
        return true
    }
    
    // MARK: - ScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == collectionView {
            self.updateCachedAssets()
        }
    }
    
    
    //MARK: - PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            guard let collection = self.assets else {
                return
            }
            guard let collectionChanges = changeInstance.changeDetails(for: collection) else {
                return
            }
            
            self.selectedAssets.removeAll()
            self.assets = collectionChanges.fetchResultAfterChanges
            let collectionView = self.collectionView!
            
            if !collectionChanges.hasIncrementalChanges ||
                collectionChanges.hasMoves {
                
                collectionView.reloadData()
                
            } else {
                
                collectionView.performBatchUpdates({
                    if let removedIndexes = collectionChanges.removedIndexes,
                        removedIndexes.count != 0 {
                        collectionView.deleteItems(at: removedIndexes.hohenheim_indexPathsFromIndexesWithSection(0))
                    }
                    
                    if let insertedIndexes = collectionChanges.insertedIndexes,
                        insertedIndexes.count != 0 {
                        collectionView.insertItems(at: insertedIndexes.hohenheim_indexPathsFromIndexesWithSection(0))
                    }
                    
                    if let changedIndexes = collectionChanges.changedIndexes,
                        changedIndexes.count != 0 {
                        collectionView.reloadItems(at: changedIndexes.hohenheim_indexPathsFromIndexesWithSection(0))
                    }
                    
                }, completion: nil)
            }
            
            self.resetCachedAssets()
        }
    }
}

internal extension UICollectionView {
    
    func hohenheim_indexPathsForElementsInRect(_ rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = self.collectionViewLayout.layoutAttributesForElements(in: rect)
        if (allLayoutAttributes?.count ?? 0) == 0 {return []}
        
        var indexPaths: [IndexPath] = []
        indexPaths.reserveCapacity(allLayoutAttributes!.count)
        
        for layoutAttributes in allLayoutAttributes! {
            let indexPath = layoutAttributes.indexPath
            indexPaths.append(indexPath)
        }
        
        return indexPaths
    }
}

internal extension IndexSet {
    
    func hohenheim_indexPathsFromIndexesWithSection(_ section: Int) -> [IndexPath] {
        var indexPaths: [IndexPath] = []
        indexPaths.reserveCapacity(self.count)
        (self as NSIndexSet).enumerate({idx, stop in
            indexPaths.append(IndexPath(item: idx, section: section))
        })
        
        return indexPaths
    }
}

private extension HHAlbumView {
    
    func changeImage(_ asset: PHAsset) {
        self.phAsset = asset
        if !self.selectedAssets.contains(asset) {
            self.selectedAssets.append(asset)
        }
        
//        DispatchQueue.global(qos: .default).async(execute: {
//            let options = PHImageRequestOptions()
//            options.isNetworkAccessAllowed = true
//
//            self.imageManager?.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFill, options: options) { result, info in
//                DispatchQueue.main.async(execute: {
//                    if let result = result {
//
//                    }
//                })
//            }
//        })
    }
    
    // Check the status of authorization for PHPhotoLibrary
    func checkPhotoAuth() {
        PHPhotoLibrary.requestAuthorization { (status) -> Void in
            switch status {
            case .authorized:
                self.imageManager = PHCachingImageManager()
                if self.assets?.count > 0 {
                    if let asset = self.assets?[0] {
                        self.changeImage(asset)
                    }
                }
                
                DispatchQueue.main.async {
                    self.delegate?.albumViewCameraRollAuthorized()
                }
                break
            case .restricted, .denied:
                DispatchQueue.main.async(execute: { () -> Void in
                    self.delegate?.albumViewCameraRollUnauthorized()
                })
                break
            default:
                break
            }
        }
    }

    // MARK: - Asset Caching
    
    func resetCachedAssets() {
        
        imageManager?.stopCachingImagesForAllAssets()
        previousPreheatRect = CGRect.zero
    }
 
    func updateCachedAssets() {
        
        guard let collectionView = self.collectionView else { return }
        
        var preheatRect = collectionView.bounds
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)
        
        let delta = abs(preheatRect.midY - self.previousPreheatRect.midY)
        
        if delta > collectionView.bounds.height / 3.0 {
            
            var addedIndexPaths: [IndexPath]   = []
            var removedIndexPaths: [IndexPath] = []
            
            self.computeDifferenceBetweenRect(
                self.previousPreheatRect,
                andRect: preheatRect,
                removedHandler: {removedRect in
                
                    let indexPaths = self.collectionView.hohenheim_indexPathsForElementsInRect(removedRect)
                    removedIndexPaths += indexPaths
                
            }, addedHandler: {addedRect in
                
                let indexPaths = self.collectionView.hohenheim_indexPathsForElementsInRect(addedRect)
                addedIndexPaths += indexPaths
            })
            
            let assetsToStartCaching = self.assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching = self.assetsAtIndexPaths(removedIndexPaths)
            
            self.imageManager?.startCachingImages(for: assetsToStartCaching,
                targetSize: cellSize,
                contentMode: .aspectFill,
                options: nil)
            
            self.imageManager?.stopCachingImages(for: assetsToStopCaching,
                targetSize: cellSize,
                contentMode: .aspectFill,
                options: nil)
            
            self.previousPreheatRect = preheatRect
        }
    }
    
    func computeDifferenceBetweenRect(_ oldRect: CGRect, andRect newRect: CGRect, removedHandler: (CGRect)->Void, addedHandler: (CGRect)->Void) {
        
        if newRect.intersects(oldRect) {
            
            let oldMaxY = oldRect.maxY
            let oldMinY = oldRect.minY
            let newMaxY = newRect.maxY
            let newMinY = newRect.minY
            
            if newMaxY > oldMaxY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: oldMaxY, width: newRect.size.width, height: (newMaxY - oldMaxY))
                addedHandler(rectToAdd)
            }
            
            if oldMinY > newMinY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: newMinY, width: newRect.size.width, height: (oldMinY - newMinY))
                addedHandler(rectToAdd)
            }
            if newMaxY < oldMaxY {
                let rectToRemove = CGRect(x: newRect.origin.x, y: newMaxY, width: newRect.size.width, height: (oldMaxY - newMaxY))
                removedHandler(rectToRemove)
            }
            if oldMinY < newMinY {
                let rectToRemove = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.size.width, height: (newMinY - oldMinY))
                removedHandler(rectToRemove)
            }
        } else {
            addedHandler(newRect)
            removedHandler(oldRect)
        }
    }
    
    func assetsAtIndexPaths(_ indexPaths: [IndexPath]) -> [PHAsset] {
        if indexPaths.count == 0 { return [] }
        var assets: [PHAsset] = []
        assets.reserveCapacity(indexPaths.count)
        for indexPath in indexPaths {
            if let asset = self.assets?[indexPath.item] {
                assets.append(asset)
            }
        }
        
        return assets
    }
}
