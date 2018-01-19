//
//  HHAlbumViewCell.swift
//  Hohenheim
//
//  Created by Elias Abel on 2015/11/14.
//  Copyright © 2015 Meniny Lab. All rights reserved.
//

import UIKit
import Photos

final class HHAlbumViewCell: UICollectionViewCell {
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var selectedLayer = CALayer()
    
    var image: UIImage? {
        
        didSet {
            
            self.imageView.image = image            
        }
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        self.isSelected = false
        
        selectedLayer.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5).cgColor
    }
    
    override var isSelected : Bool {
        
        didSet {

            if selectedLayer.superlayer == self.layer {

                selectedLayer.removeFromSuperlayer()
            }
            
            if isSelected {

                selectedLayer.frame = self.bounds
                self.layer.addSublayer(selectedLayer)
            }
        }
    }
    
}
