//
//  ViewController.swift
//  LyEditImageView
//
//  Created by Li,Yan(MMS) on 2017/6/10.
//  Copyright © 2017年 Li,Yan(MMS). All rights reserved.

//<div>Icons made by <a href="http://www.flaticon.com/authors/icon-monk" title="Icon Monk">Icon Monk</a> from <a href="http://www.flaticon.com" title="Flaticon">www.flaticon.com</a> is licensed by <a href="http://creativecommons.org/licenses/by/3.0/" title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></div>

import UIKit
import AVFoundation


class LyEditImageView: UIView, UIGestureRecognizerDelegate, CropViewDelegate {
    let CROP_VIEW_TAG = 1001
    let IMAGE_VIEW_TAG = 1002
    static let LEFT_UP_TAG = 1101
    static let LEFT_DOWN_TAG = 1102
    static let RIGHT_UP_TAG = 1103
    static let RIGHT_DOWN_TAG = 1104
    static let LEFT_LINE_TAG = 1105
    static let UP_LINE_TAG = 1106
    static let RIGHT_LINE_TAG = 1107
    static let DOWN_LINE_TAG = 1108
    
    let INIT_CROP_VIEW_SIZE = 100
    let MINIMAL_CROP_VIEW_SIZE: CGFloat = 30.0
    let MINIMUM_ZOOM_SCALE: CGFloat = 1.0
    let MAXIMUM_ZOOM_SCALE: CGFloat = 8.0
    
    let screenHeight = UIScreen.main.bounds.size.height
    let screenWidth = UIScreen.main.bounds.size.width
    
    var pinchGestureRecognizer: UIPinchGestureRecognizer!
    var panGestureRecognizer: UIPanGestureRecognizer!
    var cropViewPanGesture: UIPanGestureRecognizer!
    
    var imageView: UIImageView!
    var touchStartPoint: CGPoint!
    var originImageViewFrame: CGRect!
    var imageZoomScale: CGFloat!
    fileprivate var cropView: CropView!
    fileprivate var overLayView: OverLayView!
    
    var cropUpContraint: NSLayoutConstraint!
    var originalImageViewFrame: CGRect!
    
    var cropLeftMargin: CGFloat!
    var cropTopMargin: CGFloat!
    var cropRightMargin: CGFloat!
    var cropBottomMargin: CGFloat!
    var cropViewConstraints = [NSLayoutConstraint]()
    var cropLeftToImage: CGFloat!
    var cropTopToImage: CGFloat!
    var cropRightToImage: CGFloat!
    var cropBottomToImage: CGFloat!
    var originalSubViewFrame:CGRect!
    var cropViewConstraintsRatio: CGFloat!
    // MARK: init
    private func commitInit() {
        // set cropView
        initCropView()
        // set gesture
        initGestureRecognizer()
        
        initButton()
        
        self.isMultipleTouchEnabled = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initWithImage(image: UIImage) {
        imageView = UIImageView()
        imageView.tag = IMAGE_VIEW_TAG;
        self.addSubview(self.imageView)
        imageView.isUserInteractionEnabled = true;
        
        imageView.image = image
        imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height);
        let frame = AVMakeRect(aspectRatio: imageView.frame.size, insideRect: self.frame);
        imageView.frame = frame
        originImageViewFrame = frame
        NSLog("initWithImage %@", NSStringFromCGRect(originImageViewFrame))
        imageZoomScale = 1.0
        commitInit()
    }
    
    private func initGestureRecognizer() {

        panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture(sender:)))
        panGestureRecognizer.cancelsTouchesInView = false
        panGestureRecognizer.delaysTouchesBegan = false
        panGestureRecognizer.delaysTouchesEnded = false;
        panGestureRecognizer.delegate = self
        imageView.addGestureRecognizer(panGestureRecognizer)
        
        
        cropViewPanGesture = UIPanGestureRecognizer()
        cropViewPanGesture.addTarget(self, action: #selector(handlePanGesture(sender:)))
        cropViewPanGesture.cancelsTouchesInView = false;
        cropViewPanGesture.delaysTouchesBegan = false
        cropViewPanGesture.delaysTouchesEnded = false
        cropViewPanGesture.delegate = self
        cropView.addGestureRecognizer(cropViewPanGesture)
        
        pinchGestureRecognizer = UIPinchGestureRecognizer()
        pinchGestureRecognizer.addTarget(self, action: #selector(handlePinchGesture(sender:)))
        pinchGestureRecognizer.cancelsTouchesInView = false
        pinchGestureRecognizer.delaysTouchesBegan = false
        pinchGestureRecognizer.delaysTouchesEnded = false
        pinchGestureRecognizer.delegate = self
        self.addGestureRecognizer(pinchGestureRecognizer)
    }
    
    private func initImageView() {
       
    }

    private func initCropView() {
        initOverLayView()
        
        cropView = CropView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        cropView.tag = CROP_VIEW_TAG;
        cropView.translatesAutoresizingMaskIntoConstraints = false
        cropView.delegate = self
        self.addSubview(cropView)

        cropRightMargin = (CGFloat)(originImageViewFrame.size.width / 2) - (CGFloat)(INIT_CROP_VIEW_SIZE / 2)
        cropLeftMargin = cropRightMargin
        cropTopMargin = (CGFloat)(originImageViewFrame.size.height / 2) - (CGFloat)(INIT_CROP_VIEW_SIZE / 2) + (CGFloat)((screenHeight - originImageViewFrame.size.height) / 2)
        cropBottomMargin = cropTopMargin
        
//        cropLeftMargin = originImageViewFrame.origin.x + 10
//        cropTopMargin = originImageViewFrame.origin.y + 10
//        cropRightMargin = screenWidth - originImageViewFrame.origin.x - originImageViewFrame.size.width + 10
//        cropBottomMargin = screenHeight - originImageViewFrame.origin.y - originImageViewFrame.size.height + 10
        
        let views = ["cropView":cropView!, "imageView":imageView!] as [String : UIView]
        let Hvfl = String(format: "H:|-%f-[cropView]-%f-|", cropLeftMargin, cropRightMargin);
        let Vvfl = String(format: "V:|-%f-[cropView]-%f-|", cropTopMargin, cropBottomMargin)
        let cropViewHorizentalConstraints = NSLayoutConstraint.constraints(withVisualFormat: Hvfl, options: [], metrics: nil, views: views)
        let cropViewVerticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: Vvfl, options: [], metrics: nil, views: views)
        cropViewConstraints += cropViewHorizentalConstraints
        cropViewConstraints += cropViewVerticalConstraints
        self.addConstraints(cropViewVerticalConstraints)
        self.addConstraints(cropViewHorizentalConstraints)
        self.layoutIfNeeded()
        
        cropView.initCropViewSubViews()
        adjustOverLayView()
        //overLayView.addBlurOverLayer(cropRect: cropView.frame)
    }
    
    private func initOverLayView() {
        overLayView = OverLayView(frame: self.frame)
        self.addSubview(overLayView)
    }
    
    private func initButton() {
        let cropButton = UIButton()
        cropButton.frame = CGRect(x: screenWidth / 4 - 25, y: screenHeight - 100, width: 50, height: 50)
        cropButton.setImage(UIImage(named: "accept.png"), for: UIControlState.normal)
        cropButton.addTarget(self, action: #selector(acceptButtonAction), for: .touchUpInside)
        self.addSubview(cropButton)
        
        let rotateButton = UIButton()
        rotateButton.frame = CGRect(x: (screenWidth / 4) * 3 - 25, y: screenHeight - 100, width: 50, height: 50)
        rotateButton.setImage(UIImage(named: "rotate.png"), for: UIControlState.normal)
        rotateButton.addTarget(self, action: #selector(rotateButtonAction), for: .touchUpInside)
        self.addSubview(rotateButton)
    }
    
    private func adjustOverLayView() {
        overLayView.setOverLayView(cropRect: self.cropView.frame);
        //overLayView.setNeedsDisplay()
    }
    
    // MARK: Handle Pinch Gesture
    @objc fileprivate func handlePinchGesture(sender: UIPinchGestureRecognizer)  {
        NSLog("pinch")
        adjustAnchorPointForGesture(sender: sender)
        if sender.state == UIGestureRecognizerState.began {
            
        } else if sender.state == UIGestureRecognizerState.changed {
            imageZoomScale = imageView.frame.size.height / originImageViewFrame.size.height
            if imageZoomScale > 0.5 {
                imageView.transform = imageView.transform.scaledBy(x: sender.scale, y: sender.scale)
                sender.scale = 1
            }
            var layoutCropView = false
            if imageView.frame.origin.y > cropTopMargin {
                cropTopMargin = imageView.frame.origin.y
                layoutCropView = true
            }
            if imageView.frame.origin.x > cropLeftMargin {
                cropLeftMargin = imageView.frame.origin.x
                layoutCropView = true
            }
            if screenHeight - (imageView.frame.origin.y + imageView.frame.size.height) > cropBottomMargin {
                 cropBottomMargin = screenHeight - (imageView.frame.origin.y + imageView.frame.size.height)
                layoutCropView = true
            }
            if screenWidth - (imageView.frame.origin.x + imageView.frame.size.width) > cropRightMargin {
                 cropRightMargin = screenWidth - (imageView.frame.origin.x + imageView.frame.size.width)
                layoutCropView = true
            }
            if layoutCropView {
                updateCropViewLayout()
                adjustOverLayView()
            }
        } else if sender.state == UIGestureRecognizerState.ended
            || sender.state == UIGestureRecognizerState.cancelled {
            
            animationAfterZoom(zoomScale: imageZoomScale)
        }
    }
    
    private func adjustAnchorPointForGesture(sender: UIGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            let piceView = imageView
            let locationInView = sender.location(in: piceView)
            let locationInSuperView = sender.location(in: piceView?.superview)
            piceView?.layer.anchorPoint = CGPoint(x: locationInView.x / piceView!.bounds.size.width, y: locationInView.y / piceView!.bounds.size.height)
            piceView?.center = locationInSuperView
        }
    }
    
    private func animationAfterZoom(zoomScale: CGFloat) {
        
        
        if zoomScale <= MINIMUM_ZOOM_SCALE {
            UIView.animate(withDuration: 0.5, animations: { [unowned self] in
                self.imageView.transform = self.imageView.transform.scaledBy(x: self.MINIMUM_ZOOM_SCALE / self.imageZoomScale, y: self.MINIMUM_ZOOM_SCALE / self.imageZoomScale);
                self.imageView.frame = self.originImageViewFrame
            })
            imageZoomScale = MINIMUM_ZOOM_SCALE
        }
        
        if zoomScale >= MAXIMUM_ZOOM_SCALE {
            UIView.animate(withDuration: 0.5, animations: { [unowned self] in
                self.imageView.transform = self.imageView.transform.scaledBy(x: self.MAXIMUM_ZOOM_SCALE / self.imageZoomScale, y: self.MAXIMUM_ZOOM_SCALE / self.imageZoomScale)
            })
            imageZoomScale = MAXIMUM_ZOOM_SCALE
        }
    }
    
    // MARK: Handle Pan Gesture for CropView / ImageView
    @objc fileprivate func handlePanGesture(sender: UIPanGestureRecognizer) {
        let piceView = sender.view
        if sender.state == UIGestureRecognizerState.began {
            NSLog("gesture on view %d",cropView.getCropViewTag())
        }
        if sender.state == UIGestureRecognizerState.changed {
            if piceView?.tag == CROP_VIEW_TAG {
                handleCropViewPanGesture(sender: sender)
            } else if piceView?.tag == IMAGE_VIEW_TAG {
                panImageView(sender: sender)
            }
        }
        if sender.state == UIGestureRecognizerState.ended
            || sender.state == UIGestureRecognizerState.cancelled {
            cropView.resetHightLightView()
        }
    }
    
    // Check crop view's size incase it too small
    // Ensure crop view will not be moved out of the image view
    func handleCropViewPanGesture(sender: UIPanGestureRecognizer) {
        let tag:Int = cropView.getCropViewTag()
        let view = sender.view
        var translation = sender.translation(in: view?.superview)
        switch tag {
        case LyEditImageView.LEFT_UP_TAG:
            if translation.x + cropLeftMargin < imageView.frame.origin.x {
                translation.x = imageView.frame.origin.x - cropLeftMargin
            }
            if translation.y + cropTopMargin < imageView.frame.origin.y {
                translation.y = imageView.frame.origin.y - cropTopMargin
            }
            if screenWidth - (cropLeftMargin + translation.x  + cropRightMargin) < MINIMAL_CROP_VIEW_SIZE {
                translation.x = screenWidth - (cropLeftMargin + cropRightMargin) - MINIMAL_CROP_VIEW_SIZE;
            }
            if screenHeight - (cropTopMargin + translation.y + cropBottomMargin) < MINIMAL_CROP_VIEW_SIZE {
                translation.y = screenHeight - (cropTopMargin + cropBottomMargin) - MINIMAL_CROP_VIEW_SIZE;
            }
            cropTopMargin! += translation.y
            cropLeftMargin! += translation.x
            break
        case LyEditImageView.LEFT_DOWN_TAG:
            if translation.x + cropLeftMargin < imageView.frame.origin.x {
                translation.x = imageView.frame.origin.x - cropLeftMargin
            }
            if cropBottomMargin - translation.y < screenHeight - (imageView.frame.origin.y + imageView.frame.size.height) {
                translation.y = cropBottomMargin - (screenHeight - (imageView.frame.origin.y + imageView.frame.size.height))
            }
            if screenWidth - (cropLeftMargin + translation.x + cropRightMargin) < MINIMAL_CROP_VIEW_SIZE {
                translation.x = screenWidth - (cropLeftMargin + cropRightMargin) - MINIMAL_CROP_VIEW_SIZE;
            }
            if screenHeight - (cropTopMargin + cropBottomMargin - translation.y) < MINIMAL_CROP_VIEW_SIZE {
                translation.y = MINIMAL_CROP_VIEW_SIZE - (screenHeight - (cropTopMargin + cropBottomMargin))
            }
            cropLeftMargin! += translation.x
            cropBottomMargin! -= translation.y
            break
        case LyEditImageView.RIGHT_UP_TAG:
            if cropRightMargin - translation.x < screenWidth - (imageView.frame.origin.x + imageView.frame.size.width) {
                translation.x = cropRightMargin - (screenWidth - (imageView.frame.origin.x + imageView.frame.size.width))
            }
            if translation.y + cropTopMargin < imageView.frame.origin.y {
                translation.y = imageView.frame.origin.y - cropTopMargin
            }
            if screenWidth - (cropLeftMargin + cropRightMargin - translation.x) < MINIMAL_CROP_VIEW_SIZE {
                translation.x = MINIMAL_CROP_VIEW_SIZE - (screenWidth - (cropLeftMargin + cropRightMargin))
            }
            if screenHeight - (cropTopMargin + translation.y + cropBottomMargin) < MINIMAL_CROP_VIEW_SIZE {
                translation.y = screenHeight - (cropTopMargin + cropBottomMargin) - MINIMAL_CROP_VIEW_SIZE;
            }
            cropRightMargin! -= translation.x
            cropTopMargin! += translation.y
            
            break
        case LyEditImageView.RIGHT_DOWN_TAG:
            if cropRightMargin - translation.x < screenWidth - (imageView.frame.origin.x + imageView.frame.size.width) {
                translation.x = cropRightMargin - (screenWidth - (imageView.frame.origin.x + imageView.frame.size.width))
            }
            if cropBottomMargin - translation.y < screenHeight - (imageView.frame.origin.y + imageView.frame.size.height) {
                translation.y = cropBottomMargin - (screenHeight - (imageView.frame.origin.y + imageView.frame.size.height))
            }
            if screenWidth - (cropLeftMargin + cropRightMargin - translation.x) < MINIMAL_CROP_VIEW_SIZE {
                translation.x = MINIMAL_CROP_VIEW_SIZE - (screenWidth - (cropLeftMargin + cropRightMargin))
            }
            if screenHeight - (cropTopMargin + cropBottomMargin - translation.y) < MINIMAL_CROP_VIEW_SIZE {
                translation.y = MINIMAL_CROP_VIEW_SIZE - (screenHeight - (cropTopMargin + cropBottomMargin))
            }
            cropRightMargin! -= translation.x
            cropBottomMargin! -= translation.y
            break
        case LyEditImageView.LEFT_LINE_TAG:
            if screenWidth - (cropLeftMargin + cropRightMargin + translation.x) < MINIMAL_CROP_VIEW_SIZE {
                translation.x = screenWidth - (cropLeftMargin + cropRightMargin) - MINIMAL_CROP_VIEW_SIZE
            }
            if translation.x + cropLeftMargin < imageView.frame.origin.x {
                translation.x = imageView.frame.origin.x - cropLeftMargin
            }
            cropLeftMargin! += translation.x
            break
        case LyEditImageView.UP_LINE_TAG:
            if translation.y + cropTopMargin < imageView.frame.origin.y {
                translation.y = imageView.frame.origin.y - cropTopMargin
            }
            if screenHeight - (cropTopMargin + translation.y + cropBottomMargin) < MINIMAL_CROP_VIEW_SIZE {
                translation.y = screenHeight - (cropTopMargin + cropBottomMargin) - MINIMAL_CROP_VIEW_SIZE;
            }
            cropTopMargin! += translation.y
            break
        case LyEditImageView.RIGHT_LINE_TAG:
            if cropRightMargin - translation.x < screenWidth - (imageView.frame.origin.x + imageView.frame.size.width) {
                translation.x = cropRightMargin - (screenWidth - (imageView.frame.origin.x + imageView.frame.size.width))
            }
            if screenWidth - (cropLeftMargin + cropRightMargin - translation.x) < MINIMAL_CROP_VIEW_SIZE {
                translation.x = MINIMAL_CROP_VIEW_SIZE - (screenWidth - (cropLeftMargin + cropRightMargin))
            }
            cropRightMargin! -= translation.x
            break
        case LyEditImageView.DOWN_LINE_TAG:
            if cropBottomMargin - translation.y < screenHeight - (imageView.frame.origin.y + imageView.frame.size.height) {
                translation.y = cropBottomMargin - (screenHeight - (imageView.frame.origin.y + imageView.frame.size.height))
            }
            if screenHeight - (cropTopMargin + cropBottomMargin - translation.y) < MINIMAL_CROP_VIEW_SIZE {
                translation.y = MINIMAL_CROP_VIEW_SIZE - (screenHeight - (cropTopMargin + cropBottomMargin))
            }
            cropBottomMargin! -= translation.y
            break
        default:
            panCropView(translation: translation)
            break
        }
        
        if cropLeftMargin <= 0 {
            cropLeftMargin = 0;
        }
        if cropRightMargin < 0 {
            cropRightMargin = 0;
        }
        if cropTopMargin < 0 {
            cropTopMargin = 0;
        }
        if cropBottomMargin < 0 {
            cropBottomMargin = 0;
        }
        
        updateCropViewLayout()
        // redraw overLayView after move cropView
        adjustOverLayView()
        sender.setTranslation(CGPoint.zero, in: view?.superview)
    }
    
    private func panCropView( translation: CGPoint) {
        var translation = translation

        let right = cropRightMargin
        let left = cropLeftMargin
        let top = cropTopMargin
        let bottom = cropBottomMargin
        
        if  left! + translation.x < imageView.frame.origin.x {
            translation.x = imageView.frame.origin.x - left!
        }
        if right! - translation.x < screenWidth - (imageView.frame.origin.x + imageView.frame.size.width) {
            translation.x = right! - (screenWidth - (imageView.frame.origin.x + imageView.frame.size.width))
        }
        if top! + translation.y < imageView.frame.origin.y {
            translation.y = imageView.frame.origin.y - top!
        }
        if bottom! - translation.y < screenHeight - (imageView.frame.origin.y + imageView.frame.size.height) {
            translation.y = bottom! - (screenHeight - (imageView.frame.origin.y + imageView.frame.size.height))
        }
        if left! + translation.x < 0  {
            translation.x = -left!
        }
        if right! - translation.x < 0 {
            translation.x = right!
        }
        if top! + translation.y < 0 {
            translation.y = -top!
        }
        if bottom! - translation.y < 0 {
            translation.y = bottom!
        }
        cropRightMargin! -= translation.x
        cropLeftMargin! += translation.x
        cropBottomMargin! -= translation.y
        cropTopMargin! += translation.y
    }
    
    private func updateCropViewLayout() {
        // change cropview's constraints
        self.removeConstraints(cropViewConstraints)
        let views = ["cropView":cropView!, "imageView":imageView!] as [String : UIView]
        let Hvfl = String(format: "H:|-%f-[cropView]-%f-|", cropLeftMargin, cropRightMargin);
        let Vvfl = String(format: "V:|-%f-[cropView]-%f-|", cropTopMargin, cropBottomMargin)
        let cropViewHorizentalConstraints = NSLayoutConstraint.constraints(withVisualFormat: Hvfl, options: [], metrics: nil, views: views)
        let cropViewVerticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: Vvfl, options: [], metrics: nil, views: views)
        cropViewConstraints += cropViewHorizentalConstraints
        cropViewConstraints += cropViewVerticalConstraints
        self.addConstraints(cropViewVerticalConstraints)
        self.addConstraints(cropViewHorizentalConstraints)
        self.layoutIfNeeded()
        cropView.updateSubView()
    }
    
// MARK: Handle ImageView Pan Gesture

    func panImageView(sender: UIPanGestureRecognizer) {
        var translation = sender.translation(in:sender.view)
        translation.x = translation.x * imageZoomScale
        translation.y = translation.y * imageZoomScale
        let view = sender.view
        if (view?.frame.origin.y)! + translation.y > cropTopMargin {
            translation.y = cropTopMargin - (view?.frame.origin.y)!
        }
        if view!.frame.origin.x + translation.x > cropLeftMargin {
            translation.x = cropLeftMargin - view!.frame.origin.x
        }
        if screenHeight - (view!.frame.origin.y + view!.frame.size.height + translation.y) >  cropBottomMargin {
            translation.y = screenHeight - (view!.frame.origin.y + view!.frame.size.height) - cropBottomMargin
        }
        if screenWidth - (view!.frame.origin.x + view!.frame.size.width + translation.x) > cropRightMargin {
            translation.x = screenWidth - (view!.frame.origin.x + view!.frame.size.width) - cropRightMargin
        }
        
        view?.center = CGPoint(x: (view?.center.x)! + translation.x, y: (view?.center.y)! + translation.y)
        sender.setTranslation(CGPoint.zero, in: view?.superview)
    }
    
// MARK: Rotate Image
    
    func rotateButtonAction() {
        rotateImage()
    }
    
    // rotate imageView's image and rotate cropView
    func rotateImage() {
        let imageViewFrame = imageView.frame
        // prepare data for rotate cropView
        cropLeftToImage = cropView.frame.origin.x - imageView.frame.origin.x
        cropTopToImage = cropView.frame.origin.y - imageView.frame.origin.y
        cropRightToImage = imageView.frame.origin.x + imageView.frame.size.width - cropView.frame.origin.x - cropView.frame.size.width
        cropBottomToImage = imageView.frame.origin.y + imageView.frame.size.height - cropView.frame.origin.y - cropView.frame.size.height
        if cropLeftToImage < 0 {
            cropLeftToImage = 0
        }
        if cropTopToImage < 0 {
            cropTopToImage = 0
        }
        if cropRightToImage < 0 {
            cropRightToImage = 0
        }
        if cropBottomToImage < 0 {
            cropBottomToImage = 0
        }
        // roate image and reset image view's image
        let image = UIImage(cgImage: imageView.image!.cgImage!, scale: 1.0, orientation: .right)
        let newImage = rotateImage(source: image, withOrientation: .right)
        imageView.image = newImage
        imageView.transform = CGAffineTransform.identity
        let frame = AVMakeRect(aspectRatio: imageView.image!.size, insideRect: self.frame);
        imageView.frame = frame
        originImageViewFrame = frame
        
        // prepare data for rotate cropView, note that imageView.frame is changed
        let length1: CGFloat
        let length2: CGFloat
        if imageViewFrame.size.height > imageViewFrame.size.width {
            length1 = imageViewFrame.size.height
        } else {
            length1 = imageViewFrame.size.width
        }
        if originImageViewFrame.size.height > originImageViewFrame.size.width {
            length2 = originImageViewFrame.size.height
        } else {
            length2 = originImageViewFrame.size.width
        }
        cropViewConstraintsRatio = length2 / length1
        
        cropLeftMargin = cropBottomToImage * cropViewConstraintsRatio + imageView.frame.origin.x
        cropTopMargin = cropLeftToImage * cropViewConstraintsRatio + imageView.frame.origin.y
        cropRightMargin = cropTopToImage * cropViewConstraintsRatio + screenWidth - imageView.frame.origin.x - imageView.frame.size.width
        cropBottomMargin = cropRightToImage * cropViewConstraintsRatio + screenHeight - imageView.frame.origin.y - imageView.frame.size.height
        
        imageZoomScale = 1.0
        updateCropViewLayout()
        cropView.resetHightLightView()
        adjustOverLayView()
    }
    
    func rotateImage(source: UIImage, withOrientation orientation: UIImageOrientation) -> UIImage {
        UIGraphicsBeginImageContext(source.size)
        let context = UIGraphicsGetCurrentContext()
        if orientation == .right {
            context?.ctm.rotated(by: CGFloat.pi / 2)
        } else if orientation == .left {
            context?.ctm.rotated(by: -(CGFloat.pi / 2))
        } else if orientation == .down {
            // do nothing
        } else if orientation == .up {
            context?.ctm.rotated(by: CGFloat.pi / 2)
        }
        source.draw(at: CGPoint.zero)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
// MARK: Crop Image
    // Todo: you need to implement this function for custom purpose
    @objc private func acceptButtonAction() {
        cropImage()
    }
    
    private func cropImage() {
        let rect = self.convert(cropView.frame, to: imageView)
        let imageSize = imageView.image?.size
        let ratio = originImageViewFrame.size.width / (imageSize?.width)!
        let zoomedRect = CGRect(x: rect.origin.x / ratio, y: rect.origin.y / ratio, width: rect.size.width / ratio, height: rect.size.height / ratio)
        let croppedImage = cropImage(image: imageView.image!, toRect: zoomedRect)
    
        // delete these code for custom purpose
        var view: UIImageView? =  self.viewWithTag(1301) as? UIImageView
        if view == nil {
            view = UIImageView()
        }
        view?.frame = CGRect(x: 0, y: 0, width: croppedImage.size.width / 3, height: croppedImage.size.height / 3)
        view?.image = croppedImage
    
        view?.tag = 1301
        self.addSubview(view!)
        // delete these code for custom purpose
    }

    private func cropImage(image: UIImage, toRect rect: CGRect) -> UIImage {
        let imageRef = image.cgImage?.cropping(to: rect)
        let croppedImage = UIImage(cgImage: imageRef!)
        return croppedImage
    }
    
    func getCroppedImage() -> UIImage {
        let rect = self.convert(cropView.frame, to: imageView)
        let imageSize = imageView.image?.size
        let ratio = originImageViewFrame.size.width / (imageSize?.width)!
        let zoomedRect = CGRect(x: rect.origin.x / ratio, y: rect.origin.y / ratio, width: rect.size.width / ratio, height: rect.size.height / ratio)
        let croppedImage = cropImage(image: imageView.image!, toRect: zoomedRect)
        return croppedImage;
    }
    
// MARK: GestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}

// MARK: Inner Classes
@objc protocol CropViewDelegate {
    @objc optional func cropAddBlurOverLay(cropRect: CGRect)
    @objc optional func cropRemoveBlurOverLay()
}

private class CropView: UIView {
    
    let LINE_WIDTH:CGFloat = 2

    var leftUpCornerPoint:UIView!
    var leftDownCornerPoint:UIView!
    var rightUpCornerPoint:UIView!
    var rightDownCornerPoint:UIView!
    
    var leftLine:UIView!
    var upLine:UIView!
    var rightLine:UIView!
    var downLine:UIView!
    
    var hittedViewTag: Int?
    var delegate: CropViewDelegate?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true;
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = false;
        self.frame = frame;
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initCropViewSubViews() {
        leftLine = UIView();
        leftLine.frame = CGRect(x: 0, y: 0, width: LINE_WIDTH, height: self.frame.size.height);
        leftLine.backgroundColor = UIColor.white;
        self.addSubview(leftLine);
        leftLine.tag = LyEditImageView.LEFT_LINE_TAG;
        
        upLine = UIView();
        upLine.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: LINE_WIDTH);
        upLine.backgroundColor = UIColor.white;
        self.addSubview(upLine);
        upLine.tag = LyEditImageView.UP_LINE_TAG
        
        rightLine = UIView();
        rightLine.frame = CGRect(x: self.frame.size.width - LINE_WIDTH, y: 0, width: LINE_WIDTH, height: self.frame.size.height);
        rightLine.backgroundColor = UIColor.white;
        self.addSubview(rightLine);
        rightLine.tag = LyEditImageView.RIGHT_LINE_TAG
        
        downLine = UIView();
        downLine.frame = CGRect(x:0, y: self.frame.size.height - LINE_WIDTH, width: self.frame.size.width, height: LINE_WIDTH);
        downLine.backgroundColor = UIColor.white;
        self.addSubview(downLine);
        downLine.tag = LyEditImageView.DOWN_LINE_TAG
        
        leftUpCornerPoint = UIView()
        leftUpCornerPoint.frame = CGRect(x: -5, y: -5, width: 10, height: 10)
        leftUpCornerPoint.backgroundColor = UIColor.white
        self.addSubview(self.leftUpCornerPoint)
        leftUpCornerPoint.tag = LyEditImageView.LEFT_UP_TAG
        
        leftDownCornerPoint = UIView()
        leftDownCornerPoint.frame = CGRect(x: -5, y: self.frame.size.height - 5, width: 10, height: 10)
        leftDownCornerPoint.backgroundColor = UIColor.white
        self.addSubview(self.leftDownCornerPoint)
        leftDownCornerPoint.tag = LyEditImageView.LEFT_DOWN_TAG
        
        rightUpCornerPoint = UIView()
        rightUpCornerPoint.frame = CGRect(x: self.frame.size.width - 5, y: -5, width: 10, height: 10)
        rightUpCornerPoint.backgroundColor = UIColor.white
        self.addSubview(self.rightUpCornerPoint)
        rightUpCornerPoint.tag = LyEditImageView.RIGHT_UP_TAG
        
        rightDownCornerPoint = UIView()
        rightDownCornerPoint.frame = CGRect(x: self.frame.size.width - 5, y: self.frame.size.height - 5, width: 10, height: 10)
        rightDownCornerPoint.backgroundColor = UIColor.white
        self.addSubview(self.rightDownCornerPoint)
        rightDownCornerPoint.tag = LyEditImageView.RIGHT_DOWN_TAG
        
        //debugView()
    }
    
    // change subview's frame after cropview's constraints updated
    // hightlight the view been selected
    func updateSubView() {
        print("updateSubView")
        if hittedViewTag == LyEditImageView.LEFT_LINE_TAG {
            leftLine.frame = CGRect(x: -LINE_WIDTH, y: 0, width: LINE_WIDTH * 2, height: self.frame.size.height);
        } else {
            leftLine.frame = CGRect(x: 0, y: 0, width: LINE_WIDTH, height: self.frame.size.height);
        }
        if hittedViewTag == LyEditImageView.UP_LINE_TAG {
            upLine.frame = CGRect(x: 0, y: -LINE_WIDTH, width: self.frame.size.width, height: LINE_WIDTH * 2);
        } else {
            upLine.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: LINE_WIDTH);
        }
        if hittedViewTag == LyEditImageView.RIGHT_LINE_TAG {
            rightLine.frame = CGRect(x: self.frame.size.width - LINE_WIDTH, y: 0, width: LINE_WIDTH * 2, height: self.frame.size.height);
        } else {
            rightLine.frame = CGRect(x: self.frame.size.width - LINE_WIDTH, y: 0, width: LINE_WIDTH, height: self.frame.size.height);
        }
        if hittedViewTag == LyEditImageView.DOWN_LINE_TAG {
            downLine.frame = CGRect(x:0, y: self.frame.size.height - LINE_WIDTH, width: self.frame.size.width, height: LINE_WIDTH * 2);
        } else {
            downLine.frame = CGRect(x:0, y: self.frame.size.height - LINE_WIDTH, width: self.frame.size.width, height: LINE_WIDTH);
        }
        leftUpCornerPoint.frame = CGRect(x: -5, y: -5, width: 10, height: 10)
        leftDownCornerPoint.frame = CGRect(x: -5, y: self.frame.size.height - 5, width: 10, height: 10)
        rightUpCornerPoint.frame = CGRect(x: self.frame.size.width - 5, y: -5, width: 10, height: 10)
        rightDownCornerPoint.frame = CGRect(x: self.frame.size.width - 5, y: self.frame.size.height - 5, width: 10, height: 10)
    }
    
    // override point inside to enlarge subview's touch zone
    // and add tag to subviews
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var pointInside = false
        
        if self.frame.contains(convert(point, to: self.superview)) {
            pointInside = true
            hittedViewTag = self.tag
        }
        
        for subview in subviews as [UIView] {
            if !subview.isHidden && subview.alpha > 0
                && subview.isUserInteractionEnabled {
                var extendFrame: CGRect
                if subview.tag == LyEditImageView.UP_LINE_TAG || subview.tag == LyEditImageView.DOWN_LINE_TAG {
                    extendFrame = CGRect(x: subview.frame.origin.x + 25, y: subview.frame.origin.y - 20, width: subview.frame.size.width - 50, height: subview.frame.size.height + 40)
                    
                } else if subview.tag == LyEditImageView.LEFT_LINE_TAG || subview.tag == LyEditImageView.RIGHT_LINE_TAG {
                    extendFrame = CGRect(x: subview.frame.origin.x - 20, y: subview.frame.origin.y + 25, width: subview.frame.size.width + 40, height: subview.frame.size.height - 50)
                    
                } else {
                    extendFrame = CGRect(x: subview.frame.origin.x - 20, y: subview.frame.origin.y - 20, width: subview.frame.size.width + 40, height: subview.frame.size.height + 40)
                }
                if extendFrame.contains(point) {
                    hittedViewTag = subview.tag
                    pointInside = true
                }
            }
        }
        
        return pointInside
    }
    
    func getCropViewTag() -> Int {
       if let tag = hittedViewTag {
            return tag
        }
        return 0;
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("cropview began")
        updateSubView()
        delegate?.cropRemoveBlurOverLay?()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("cropview end")
        resetHightLightView()
        delegate?.cropAddBlurOverLay?(cropRect: self.frame)
    }
    
    func resetHightLightView() {
        print("resetHightLightView")
        leftLine.frame = CGRect(x: 0, y: 0, width: LINE_WIDTH, height: self.frame.size.height);
        upLine.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: LINE_WIDTH);
        rightLine.frame = CGRect(x: self.frame.size.width - LINE_WIDTH, y: 0, width: LINE_WIDTH, height: self.frame.size.height);
        downLine.frame = CGRect(x:0, y: self.frame.size.height - LINE_WIDTH, width: self.frame.size.width, height: LINE_WIDTH);
    }
    
    func debugView() {
        for subview in subviews {
            subview.isUserInteractionEnabled = true;
            //test
            subview.backgroundColor = UIColor.blue
            var extendFrame: CGRect
            if subview.tag == LyEditImageView.UP_LINE_TAG || subview.tag == LyEditImageView.DOWN_LINE_TAG {
                extendFrame = CGRect(x: subview.frame.origin.x + 25, y: subview.frame.origin.y - 20, width: subview.frame.size.width - 50, height: subview.frame.size.height + 40)
                subview.backgroundColor = UIColor.red
            } else if subview.tag == LyEditImageView.LEFT_LINE_TAG || subview.tag == LyEditImageView.RIGHT_LINE_TAG {
                extendFrame = CGRect(x: subview.frame.origin.x - 20, y: subview.frame.origin.y + 25, width: subview.frame.size.width + 40, height: subview.frame.size.height - 50)
                subview.backgroundColor = UIColor.red
            } else {
                extendFrame = CGRect(x: subview.frame.origin.x - 20, y: subview.frame.origin.y - 20, width: subview.frame.size.width + 40, height: subview.frame.size.height + 40)
            }
            subview.frame = extendFrame
        }
    }
}

private class OverLayView: UIView {
    var cropRect : CGRect?
    var blurEffectView: UIVisualEffectView!
    var blurEffect: UIBlurEffect!
    var delayTask: DispatchWorkItem!
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false;
        self.backgroundColor = UIColor.clear;
        blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        delayTask = DispatchWorkItem { [unowned self] in
            UIView.animate(withDuration: 0.5, animations: {
                self.blurEffectView.alpha = 1
            })
        }
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func setOverLayView(cropRect: CGRect) {
        self.cropRect = cropRect
        self.setNeedsDisplay()
    }
    override func draw(_ rect: CGRect) {
        UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2).set()
        UIRectFill(self.frame)
        let intersecitonRect = self.frame.intersection(self.cropRect!)
        UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0).set()
        UIRectFill(intersecitonRect)
    }
    
}

