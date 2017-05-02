//
//  DraggableView.swift
//  Edumate
//
//  Created by Rodrigo Mantica on 2/28/16.
//  Copyright © 2016 Rodrigo Mantica. All rights reserved.
//

import Foundation
import UIKit

let ACTION_MARGIN: CGFloat = 120      // distance from center where the action applies. Higher = swipe further in order for the action to be called
let SCALE_STRENGTH: CGFloat = 4       // how quickly the card shrinks. Higher = slower shrinking
let SCALE_MAX: CGFloat = 0.94          // upper bar for how much the card shrinks. Higher = shrinks less
let ROTATION_MAX: CGFloat = 1         // the maximum rotation allowed in radians.  Higher = card can keep rotating longer
let ROTATION_STRENGTH: CGFloat = 320  // strength of rotation. Higher = weaker rotation
let ROTATION_ANGLE: CGFloat = 3.14/6  // Higher = stronger rotation angle

protocol DraggableViewDelegate {
    
    func cardSwipedLeft(_ card: UIView) -> Void
    func cardSwipedRight(_ card: UIView) -> Void
    func cardSwipedUp(_ card: UIView) -> Void
    func cardSwipedDown(_ card: UIView) -> Void
    
}

class DraggableView: UIView {
    
    fileprivate var delegate: DraggableViewDelegate!
    fileprivate var panGestureRecognizer: UIPanGestureRecognizer!
    fileprivate var originPoint: CGPoint!
    fileprivate var xFromCenter: CGFloat!
    fileprivate var yFromCenter: CGFloat!
    
    var user: User?
    
    var nameLabel: UILabel!
    var universityLabel: UILabel!
    var imageView: UIImageView!
    var tutorLabel: UILabel!
    var coursesLabel: UILabel!
    
    fileprivate var overlayView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(beingDragged))
        self.panGestureRecognizer.cancelsTouchesInView = false
        self.addGestureRecognizer(panGestureRecognizer)
        
        self.originPoint = self.center
        
        self.xFromCenter = 0
        self.yFromCenter = 0
        
        self.nameLabel = UILabel(frame: CGRect(x: 10, y: 10, width: frame.size.width - 20, height: 20))
        self.nameLabel.textAlignment = .center
        self.nameLabel.textColor = UIColor.black
        self.nameLabel.adjustsFontSizeToFitWidth = true
        self.nameLabel.minimumScaleFactor = 0.75
        self.nameLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightBold)
        self.addSubview(self.nameLabel)
            
        self.universityLabel = UILabel(frame: CGRect(x: 10, y: 30, width: frame.size.width - 20, height: frame.size.height/2 - 130))
        self.universityLabel.textAlignment = .center
        self.universityLabel.textColor = UIColor.darkGray
        self.universityLabel.numberOfLines = 2
        self.universityLabel.lineBreakMode = .byWordWrapping
        self.universityLabel.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightSemibold)
        self.addSubview(self.universityLabel)
            
        self.imageView = UIImageView(frame: CGRect(x: frame.size.width/2 - 100, y: frame.size.height/2 - 100, width: 200, height: 200))
        self.imageView.layer.cornerRadius = self.imageView.frame.size.height/2
        self.imageView.clipsToBounds = true
        self.imageView.contentMode = .scaleAspectFill
        self.addSubview(self.imageView)
        
        self.tutorLabel = UILabel(frame: CGRect(x: frame.size.width/2 - 25, y: frame.size.height/2 + 85, width: 60, height: 20))
        self.tutorLabel.text = "TUTOR"
        self.tutorLabel.textAlignment = .center
        self.tutorLabel.textColor = UIColor.white
        self.tutorLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightBold)
        self.tutorLabel.backgroundColor = Constants.data.lightGreen
        self.tutorLabel.layer.cornerRadius = 5
        self.tutorLabel.clipsToBounds = true
        self.tutorLabel.isHidden = true
        self.addSubview(self.tutorLabel)
            
        self.coursesLabel = UILabel(frame: CGRect(x: 10, y: frame.size.height/2 + 100, width: frame.size.width - 20, height: frame.size.height/2 - 105))
        self.coursesLabel.textAlignment = .center
        self.coursesLabel.textColor = UIColor.black
        self.coursesLabel.lineBreakMode = .byWordWrapping
        self.coursesLabel.numberOfLines = 0
        self.coursesLabel.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
        self.addSubview(self.coursesLabel)
        
        self.overlayView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        self.overlayView.layer.cornerRadius = 10
        self.overlayView.alpha = 0
        self.addSubview(self.overlayView)
        
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(frame: CGRect, title: String, subtitle: NSAttributedString, image: UIImage, tutors: Bool, text: NSAttributedString, user: User?, delegate: DraggableViewDelegate) {
        self.init(frame: frame)
        self.nameLabel.text = title
        self.universityLabel.attributedText = subtitle
        self.imageView.image = image
        self.tutorLabel.isHidden = !tutors
        self.coursesLabel.attributedText = text
        self.user = user
        self.delegate = delegate
    }
    
    fileprivate func setupView() {
        self.backgroundColor = UIColor.white
        self.layer.cornerRadius = 10
        self.addDropShadow()
    }

    func beingDragged(_ gestureRecognizer: UIPanGestureRecognizer) {
        self.xFromCenter = gestureRecognizer.translation(in: self).x
        self.yFromCenter = gestureRecognizer.translation(in: self).y
        
        switch gestureRecognizer.state {
        case UIGestureRecognizerState.began:
            self.originPoint = self.center
        case UIGestureRecognizerState.changed:
            let rotationStrength = min(xFromCenter/ROTATION_STRENGTH, ROTATION_MAX)
            let rotationAngle = ROTATION_ANGLE * rotationStrength
            let scale = max(1 - fabs(rotationStrength) / SCALE_STRENGTH, SCALE_MAX)
            
            if yFromCenter > 0 {
                // Fade text elements
                self.nameLabel.alpha = 1 - self.yFromCenter * 0.05
                self.universityLabel.alpha = 1 - self.yFromCenter * 0.05
                self.coursesLabel.alpha = 1 - CGFloat(self.yFromCenter) * 0.05
            }
            
            self.center = CGPoint(x: self.originPoint.x + xFromCenter, y: self.originPoint.y + yFromCenter)

            let transform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle))
            let scaleTransform = transform.scaledBy(x: scale, y: scale)
            self.transform = scaleTransform
            self.updateOverlay(self.xFromCenter, y: self.yFromCenter)
        case UIGestureRecognizerState.ended:
            self.afterSwipeAction()
        case UIGestureRecognizerState.possible:
            fallthrough
        case UIGestureRecognizerState.cancelled:
            fallthrough
        case UIGestureRecognizerState.failed:
            fallthrough
        default:
            break
        }
    }

    fileprivate func updateOverlay(_ x: CGFloat, y: CGFloat) {
        if y > 50 {
            self.overlayView.backgroundColor = Constants.data.lightGreen
        } else if x != 0 {
            self.overlayView.backgroundColor = Constants.data.fadedRed
        }
        self.overlayView.alpha = min(fabs(y)/1000 + fabs(x)/1000, 0.4)
    }

    fileprivate func afterSwipeAction() {
        if self.xFromCenter > ACTION_MARGIN {
            self.completeSwipeRight()
        } else if self.xFromCenter < -ACTION_MARGIN {
            self.completeSwipeLeft()
        } else if self.yFromCenter > ACTION_MARGIN {
            self.completeSwipeDown()
        } else if self.yFromCenter < -ACTION_MARGIN {
            self.completeSwipeUp()
        } else {
            UIView.animate(withDuration: 0.3, animations: {() -> Void in
                self.center = self.originPoint
                self.transform = CGAffineTransform(rotationAngle: 0)
                self.overlayView.alpha = 0
                self.nameLabel.alpha = 1
                self.universityLabel.alpha = 1
                self.coursesLabel.alpha = 1
            })
        }
    }
    
    func completeSwipeRight() {
        let finishPoint: CGPoint = CGPoint(x: 800, y: 2 * CGFloat(self.yFromCenter) + self.originPoint.y)
        completeSwipe(finishPoint, rotateRadians: ROTATION_MAX, callback: self.delegate.cardSwipedRight)
    }

    func completeSwipeLeft() {
        let finishPoint: CGPoint = CGPoint(x: -800, y: 2 * self.yFromCenter + self.originPoint.y)
        completeSwipe(finishPoint, rotateRadians: -ROTATION_MAX, callback: self.delegate.cardSwipedLeft)
    }
    
    func completeSwipeUp() {
        let finishPoint: CGPoint = CGPoint(x: self.center.x, y: -800)
        completeSwipe(finishPoint, rotateRadians: ROTATION_MAX, callback: self.delegate.cardSwipedUp)
    }
    
    func completeSwipeDown() {
        let finishPoint: CGPoint = CGPoint(x: self.center.x, y: 800)
        completeSwipe(finishPoint, rotateRadians: ROTATION_MAX, callback: self.delegate.cardSwipedDown)
    }
    
    fileprivate func completeSwipe(_ finishPoint: CGPoint, rotateRadians: CGFloat, callback: (UIView) -> ()) {
        UIView.animate(withDuration: 0.3,
                                   animations: {
                                    self.center = finishPoint
                                    self.transform = CGAffineTransform(rotationAngle: rotateRadians)
                                    self.overlayView.alpha = 0.4
            }, completion: {
                (value: Bool) in
                self.removeFromSuperview()
        })
        callback(self)
    }
    
}
