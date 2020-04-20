//
//  ViewController.swift
//  CoreML-PhotoClassification
//
//  Created by elaine on 2020/4/20.
//  Copyright © 2020 yuri. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var btn: UIButton!
    
    @IBOutlet var imageView: UIImageView!

    @IBOutlet var classifier: UILabel!
    
    var model:SqueezeNet!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        btn.layer.cornerRadius = 8
    }

    override func viewWillAppear(_ animated: Bool) {
        model = SqueezeNet()
    }

    
    @IBAction func pickImageBtnClick(_ sender: UIButton) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    //The imagePickerController method
    //is called when the user is finished //selecting the image from the //library. Hence, we will use this //method to set the selected image //in the Image View of our //application.
    //UIImagePickerControllerDelegate Methods

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        imageView.image = pickedImage
        picker.dismiss(animated: true)
        
        //the input that our model takes in is an image of size 227×227. Thus, we will need to resize the image after the user is done selecting the image.
        //resize image.
        
        //convert the selected image to that size and assign it to a new variable called newImage.
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 227, height: 227), true, 2.0)
        pickedImage.draw(in: CGRect(x: 0, y: 0, width: 227, height: 227))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        //store the newImage in the form of a pixel buffer
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {return}
        
        // all the pixels present in the image are converted into device- dependent RGB color space.
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        // store the pixel data in CGContext so that we can easily modify some properties of the image pixels.
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        //scale the image as per our requirement.
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        //update the final image buffer.
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        
        //predict image label
        guard let prediction = try? model.prediction(image: pixelBuffer!) else {
        classifier.text = "Can't Predict!"
        return
        }
        classifier.text = "This is probably \(prediction.classLabel)."
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
        
    }

}

