//
//  ViewController.swift
//  Test
//
//  Created by Luca on 6/6/18.
//  Copyright © 2018 aaa. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var selectedIndex: Int = 0
    var arrData: NSMutableArray = NSMutableArray()

    @IBOutlet weak var collectionView: UICollectionView!
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let captureDevice = AVCaptureDevice.default(for: .video)
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
        } catch {
            print(error)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: -
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrData.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let row = indexPath.row
        if (row < arrData.count) {
            let dic = arrData[row] as! NSDictionary
            let type = dic["type"] as! String
            
            print(type)
            
            if (type == "photo") {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
                cell.layer.borderWidth = 1
                cell.layer.borderColor = UIColor.gray.cgColor
                
                let img = dic["data"] as! UIImage
                cell.photo.image = img
                
                return cell
            } else if (type == "video") {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
                cell.layer.borderWidth = 1
                cell.layer.borderColor = UIColor.gray.cgColor
                
                let videoUrl = dic["data"] as! URL
                
                let player = AVPlayer(url: videoUrl)
                cell.setPlayer(player: player)
                
                return cell
            }
            
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.gray.cgColor
        cell.photo.image = UIImage(named: "plus")
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedIndex = indexPath.row
        let alertController = UIAlertController(title: "Select Type", message: nil, preferredStyle: .actionSheet)
        let photo = UIAlertAction(title: "Take a Photo", style: .default) { (action) in
            let vc = UIImagePickerController()
            vc.sourceType = .camera
            vc.allowsEditing = true
            vc.delegate = self
            self.present(vc, animated: true)
        }
        
        let video = UIAlertAction(title: "Record Video", style: .default) { (action) in
            
            let vc = UIImagePickerController()
            vc.sourceType = .camera
            vc.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String]
            vc.delegate = self
            self.present(vc, animated: true)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(photo)
        alertController.addAction(video)
        alertController.addAction(cancel)
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            let dic: NSDictionary = [ "type": "photo", "data": image ]
            print(image.size)
            
            if (self.selectedIndex < arrData.count) {
                self.arrData.replaceObject(at: self.selectedIndex, with: dic)
            } else {
                self.arrData.add(dic)
            }
            
            self.collectionView.reloadData()
        }
        
        // video
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? NSURL {
            let data = NSData(contentsOf: videoUrl as URL)!
            print("File size before compression: \(Double(data.length / 1048576)) mb")
            compressWithSessionStatusFunc(videoUrl)
        }
        
        
    }
    
    //MARK: Video Compressing technique
    fileprivate func compressWithSessionStatusFunc(_ videoUrl: NSURL) {
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".MOV")
        compressVideo(inputURL: videoUrl as URL, outputURL: compressedURL) { (exportSession) in
            guard let session = exportSession else {
                return
            }
            
            switch session.status {
            case .unknown:
                break
            case .waiting:
                break
            case .exporting:
                break
            case .completed:
                guard let compressedData = NSData(contentsOf: compressedURL) else {
                    return
                }
                print("File size after compression: \(Double(compressedData.length / 1048576)) mb")
                
                DispatchQueue.main.async {
                    
                    let dic: NSDictionary = [ "type": "video", "data": compressedURL ]
                    
                    if (self.selectedIndex < self.arrData.count) {
                        self.arrData.replaceObject(at: self.selectedIndex, with: dic)
                    } else {
                        self.arrData.add(dic)
                    }
                    
                    self.collectionView.reloadData()
                }
                
            case .failed:
                break
            case .cancelled:
                break
            }
        }
    }
    
    // Now compression is happening with medium quality, we can change when ever it is needed
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset1280x720) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mov
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
    
}

