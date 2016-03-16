//
//  PhotoBrowser.swift
//  PhotoBrowser
//
//  Created by WangWei on 16/2/3.
//  Copyright © 2016年 Teambition. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

let ToolbarHeight: CGFloat = 44
let PadToolbarItemSpace: CGFloat = 72

@objc public protocol PhotoBrowserDelegate: NSObjectProtocol {
    optional func dismissPhotoBrowser(photoBrowser: PhotoBrowser)
    optional func longPressOnImage(gesture: UILongPressGestureRecognizer)
}

public class PhotoBrowser: UIPageViewController {
    
    var isFullScreen = false
    var toolbarHeightConstraint: NSLayoutConstraint?
    var toolbarBottomConstraint: NSLayoutConstraint?
    var navigationTopConstraint: NSLayoutConstraint?
    var navigationHeightConstraint: NSLayoutConstraint?
    
    var headerView: PBNavigationBar?
    
    var transitionDelegate: TransitionDelegate? {
        didSet {
            transitioningDelegate = transitionDelegate
        }
    }
    
    public var photos: [Photo]?
    public var toolbar: PBToolbar?
    public var backgroundColor = UIColor.blackColor()
    public weak var photoBrowserDelegate: PhotoBrowserDelegate?
    
    public var currentIndex: Int = 0
    public var currentPhoto: Photo? {
        return photos?[currentIndex]
    }
    
    public override init(transitionStyle style: UIPageViewControllerTransitionStyle, navigationOrientation: UIPageViewControllerNavigationOrientation, options: [String : AnyObject]?) {
        super.init(transitionStyle: style, navigationOrientation: navigationOrientation, options: options)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public convenience init() {
        self.init(transitionStyle: UIPageViewControllerTransitionStyle.Scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal, options: [UIPageViewControllerOptionInterPageSpacingKey:20])
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundColor
        extendedLayoutIncludesOpaqueBars = true
        automaticallyAdjustsScrollViewInsets = false
        edgesForExtendedLayout = UIRectEdge.Top
        dataSource = self
        delegate = self
        
        if let photos = photos {
            let initPage = PhotoPreviewController(photo: photos[currentIndex], index: currentIndex)
            initPage.delegate = self
            setViewControllers([initPage], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
        }
        
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updateNavigationBarTitle()
        updateToolbar(view.bounds.size)
    }
    
    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        updateToolbar(size)
    }
    
    public override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

extension PhotoBrowser {
    
    public override func prefersStatusBarHidden() -> Bool {
        return isFullScreen
    }
    
    public override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Fade
    }
    
    func updateNavigationBarTitle() {
        guard let photos = photos else {
            return
        }
        
        if headerView == nil {
            headerView = PBNavigationBar()
            if let headerView = headerView {
                view.addSubview(headerView)
                headerView.translatesAutoresizingMaskIntoConstraints = false
                view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[headerView]-0-|", options: [], metrics: nil, views: ["headerView":headerView]))
                navigationHeightConstraint = NSLayoutConstraint(item: headerView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 64)
                navigationTopConstraint = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: headerView, attribute: .Top, multiplier: 1.0, constant: 0)
                if let topConstraint = navigationTopConstraint, let heightConstraint = navigationHeightConstraint {
                    view.addConstraints([topConstraint, heightConstraint])
                }
                
                headerView.leftButton.addTarget(self, action: "leftButtonTap:", forControlEvents: .TouchUpInside)
                headerView.rightButton.addTarget(self, action: "rightButtonTap:", forControlEvents: .TouchUpInside)
            }
        }
        if let headerView = headerView {
            headerView.titleLabel.text = photos[currentIndex].title
            headerView.indexLabel.text = "\(currentIndex + 1)/\(photos.count)"
        }
    }
    
    func updateToolbar(size: CGSize) {
        guard let items = toolbarItems where items.count > 0 else {
            return
        }
        if toolbar == nil {
            toolbar = PBToolbar()
            if let toolbar = toolbar {
                view.addSubview(toolbar)
                toolbar.translatesAutoresizingMaskIntoConstraints = false
                view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[toolbar]-0-|", options: [], metrics: nil , views: ["toolbar":toolbar]))
                toolbarBottomConstraint = NSLayoutConstraint(item: bottomLayoutGuide, attribute: .Top, relatedBy: .Equal, toItem: toolbar, attribute: .Bottom, multiplier: 1.0, constant: 0)
                toolbarHeightConstraint = NSLayoutConstraint(item: toolbar, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: ToolbarHeight)
                if let heightConstraint = toolbarHeightConstraint, let bottomConstraint = toolbarBottomConstraint {
                    view.addConstraint(bottomConstraint)
                    toolbar.addConstraint(heightConstraint)
                }
            }
        }
        if let toolbar = toolbar {
            let itemsArray = layoutToolbar(items)
            toolbar.setItems(itemsArray, animated: false)
        }
    }
    
    func layoutToolbar(items: [UIBarButtonItem]) -> [UIBarButtonItem]? {
        let flexSpace = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: self, action: nil)
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: self, action: nil)
        fixedSpace.width = PadToolbarItemSpace
        var itemsArray = [UIBarButtonItem]()
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            itemsArray.append(flexSpace)
            for item in items {
                itemsArray.append(item)
                itemsArray.append(fixedSpace)
            }
            itemsArray.removeLast()
            itemsArray.append(flexSpace)
        } else {
            if items.count == 1, let first = items.first {
                itemsArray = [flexSpace, first, flexSpace]
            } else if items.count == 2, let first = items.first, let last = items.last {
                itemsArray = [flexSpace, first, flexSpace, flexSpace, last, flexSpace]
            } else {
                for item in items {
                    itemsArray.append(item)
                    itemsArray.append(flexSpace)
                }
                if itemsArray.count > 0 {
                    itemsArray.removeLast()
                }
            }
        }
        
        return itemsArray
    }
    
    func leftButtonTap(sender: AnyObject) {
        if let delegate = photoBrowserDelegate where delegate.respondsToSelector("dismissPhotoBrowser:") {
            delegate.dismissPhotoBrowser!(self)
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func rightButtonTap(sender: AnyObject) {
        
        if let image = currentImageView()?.image, let button = sender as? UIButton {
            let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            
            switch UIDevice.currentDevice().userInterfaceIdiom {
            case .Phone:
                presentViewController(activityController, animated: true, completion: nil)
            case .Pad:
                let popover = UIPopoverController(contentViewController: activityController)
                popover.presentPopoverFromRect(button.frame, inView: view, permittedArrowDirections: .Any, animated: true)
            default:
                presentViewController(activityController, animated: true, completion: nil)
            }
        }
    }
    
}

extension PhotoBrowser: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    public func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? PhotoPreviewController else {
            return nil
        }
        guard let index = viewController.index, let photos = photos else {
            return nil
        }
        if index < 1 {
            return nil
        }
        let prePhoto = photos[index - 1]
        let preViewController = PhotoPreviewController(photo: prePhoto, index: index - 1)
        preViewController.delegate = self
        return preViewController
    }
    
    public func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? PhotoPreviewController else {
            return nil
        }
        guard let index = viewController.index else {
            return nil
        }
        guard let photos = photos else {
            return nil
        }
        if index + 1 > photos.count - 1 {
            return nil
        }
        let nextPhoto = photos[index + 1]
        let nextViewController = PhotoPreviewController(photo: nextPhoto, index: index + 1)
        nextViewController.delegate = self
        
        return nextViewController
    }
    
    public func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            guard let currentViewController = pageViewController.viewControllers?.last as? PhotoPreviewController else {
                return
            }
            if let index = currentViewController.index {
                currentIndex = index
                updateNavigationBarTitle()
            }
        }
    }
}

extension PhotoBrowser: PhotoPreviewControllerDelegate {
    
    var isFullScreenMode: Bool {
        get {
            return isFullScreen
        }
        
        set(newValue) {
            isFullScreen = newValue
            UIView.animateWithDuration(0.3) { () -> Void in
                self.setNeedsStatusBarAppearanceUpdate()
                self.view.backgroundColor = newValue ? UIColor.blackColor() : self.backgroundColor
                self.headerView?.alpha = newValue ? 0 : 1
                self.toolbar?.alpha = newValue ? 0 : 1
            }
        }
    }
    
    func longPressOn(photo: Photo, gesture: UILongPressGestureRecognizer) {
        guard let browserDelegate = photoBrowserDelegate else {
            return
        }
        if browserDelegate.respondsToSelector("longPressOnImage:") {
            browserDelegate.longPressOnImage!(gesture)
        }
    }
}

extension PhotoBrowser {
    func currentImageView() -> UIImageView? {
        guard let page = viewControllers?.last as? PhotoPreviewController else {
            return nil
        }
        return page.imageView
    }
}
