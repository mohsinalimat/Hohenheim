//
//  ViewController.swift
//  Hohenheim
//
//  Created by Elias Abel on 01/31/2016.
//  Copyright (c) 2016 Meniny Lab. All rights reserved.
//

import UIKit
import Hohenheim
import AssetsLibrary
import Photos

class ViewController: UIViewController, HohenheimDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var fileUrlLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        showButton.layer.cornerRadius = 2.0
        self.fileUrlLabel.text = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public var isSimulator: Bool = {
        #if (arch(i386) || arch(x86_64)) && !os(OSX) && !os(Linux)
            return true
        #else
            return false
        #endif
    }()
    
    @IBAction func showButtonPressed(_ sender: AnyObject) {
        
        // Show Hohenheim
        let hohenheim = HohenheimViewController()
        
        hohenheim.delegate = self
        hohenheim.allowMultipleSelection = true
        if isSimulator {
            hohenheim.availableModes = [.library]
        } else {
            hohenheim.availableModes = HohenheimSource.all
        }
        HohenheimConfiguration.shouldAutoSavesVideo = true
        HohenheimConfiguration.shouldAutoSavesImage = true

        self.present(hohenheim, animated: true, completion: nil)
    }
    
    // MARK: FusumaDelegate Protocol
    func hohenheim(_ controller: HohenheimViewController, didSelectItems items: [HohenheimItem], from source: HohenheimSource) {
        
        switch source {
            
        case .camera:
            
            print("Image captured from Camera")
            
        case .library:
            
            print("Image selected from Camera Roll")
            
        default:
            
            print("Image selected")
        }
        
        print("Number of selection images: \(items.count)")

        var count: Double = 0
        
        for item in items {
            DispatchQueue.main.asyncAfter(deadline: .now() + (3.0 * count)) {
                self.imageView.image = item.image
                print("w: \(item.image.size.width) - h: \(item.image.size.height)")
            }
            count += 1
        }
    }

    func hohenheim(_ controller: HohenheimViewController, didCaptureVideo fileURL: URL) {
        print("video completed and output to file: \(fileURL)")
        self.fileUrlLabel.text = "file output to: \(fileURL.absoluteString)"
    }
    
    func hohenheimCameraRollUnauthorized(_ controller: HohenheimViewController) {
        
        print("Camera roll unauthorized")
        
        let alert = UIAlertController(title: "Access Requested",
                                      message: "Saving image needs to access your photo album",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { (action) -> Void in
            
            if let url = URL(string:UIApplicationOpenSettingsURLString) {
                
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            
        })

        guard let vc = UIApplication.shared.delegate?.window??.rootViewController,
            let presented = vc.presentedViewController else {
            
            return
        }
        
        presented.present(alert, animated: true, completion: nil)
    }
    
    func hohenheimDidDismiss(_ controller: HohenheimViewController) {
        print("Called when the FusumaViewController disappeared")
    }
    
    func hohenheimWillDismiss(_ controller: HohenheimViewController) {
        print("Called when the close button is pressed")
    }

}

