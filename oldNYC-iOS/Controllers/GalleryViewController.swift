//
//  GalleryViewController.swift
//  ImageViewer
//
//  Created by Kristian Angyal on 29/02/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import UIKit
import WebKit

final public class GalleryViewController : UIPageViewController, UIViewControllerTransitioningDelegate, ImageViewControllerDelegate  {
    
    /// UI
    fileprivate var closeButton: UIButton?
    fileprivate var detailButton: UIButton?
    fileprivate var shareButton: UIButton?
    /// You can set any UIView subclass here. If set, it will be integrated into view hierachy and laid out 
    /// following either the default pinning settings or settings from a custom configuration.
    public var headerView: UIView?
    /// Behaves the same way as header view above, the only difference is this one is pinned to the bottom.
    public var footerView: UIView?
    fileprivate var applicationWindow: UIWindow? {
        return UIApplication.shared.delegate?.window?.flatMap { $0 }
    }
    
    /// DATA
    fileprivate let imageProvider: ImageProvider
    fileprivate let displacedView: UIView
    fileprivate let imageCount: Int
    fileprivate let startIndex: Int
    
    fileprivate var galleryDatasource: GalleryViewControllerDatasource!
    fileprivate let fadeInHandler = ImageFadeInHandler()
    fileprivate var galleryPagingMode = GalleryPagingMode.standard
    var currentIndex: Int
    fileprivate var isDecorationViewsHidden = false
    fileprivate var isAnimating = false
    
    /// LOCAL CONFIG
    fileprivate let configuration: GalleryConfiguration
    fileprivate var spinnerColor = UIColor.white
    fileprivate var spinnerStyle = UIActivityIndicatorView.Style.white
    fileprivate let presentTransitionDuration = 0.25
    fileprivate let dismissTransitionDuration = 1.00
    fileprivate let closeButtonPadding: CGFloat = 0.0
    fileprivate let detailButtonPadding: CGFloat = 0.0
    fileprivate let shareButtonPadding: CGFloat = 0.0
    fileprivate let headerViewMarginTop: CGFloat = 20
    fileprivate let swipeToDismissFadeOutAccelerationFactor: CGFloat = 6
    fileprivate let toggleHeaderFooterAnimationDuration = 0.15
    fileprivate let closeAnimationDuration = 0.2
    fileprivate let rotationAnimationDuration = 0.0
    fileprivate var closeLayout = CloseButtonLayout.pinLeft(1,1)
    fileprivate var detailLayout = DetailButtonLayout.pinRight(1, 50)
    fileprivate var shareLayout = ShareButtonLayout.pinRight(1, 1)
    fileprivate var headerLayout = HeaderLayout.center(15)
    fileprivate var footerLayout = FooterLayout.pinLeft(1, 1)
    fileprivate var statusBarHidden = true
    
    /// TRANSITIONS
    fileprivate let presentTransition: GalleryPresentTransition
    fileprivate let closeTransition: GalleryCloseTransition
    
    /// COMPLETION
    /// If set ,the block is executed right after the initial launc hanimations finish.
    public var launchedCompletion: (() -> Void)?
    /// If set, called everytime ANY animation stops in the page controller stops and the viewer passes a page index of the page that is currently on screen
    public var landedPageAtIndexCompletion: ((Int) -> Void)?
    /// If set, launched after all animations finish when the close button is pressed.
    public var closedCompletion: (() -> Void)?
    /// If set, launched after all animations finish when the swipe-to-dismiss (applies to all directions and cases) gesture is used.
    public var swipedToDismissCompletion: (() -> Void)?
    
    /// IMAGE VC FACTORY
    fileprivate var imageControllerFactory: ImageViewControllerFactory!
    
    // MARK: - VC Setup
    
    public init(imageProvider: ImageProvider,
                displacedView: UIView,
                imageCount: Int,
                startIndex: Int,
                configuration: GalleryConfiguration? = nil) {
        
        self.imageProvider = imageProvider
        self.displacedView = displacedView
        self.imageCount = imageCount
        self.startIndex = startIndex
        self.currentIndex = startIndex
        self.configuration = configuration ?? defaultGalleryConfiguration()
        
        var dividerWidth: Float = 10
        
        for item in self.configuration {
            
            switch item {
                
            case .imageDividerWidth(let width):
                dividerWidth = Float(width)
            case .spinnerStyle(let style):
                spinnerStyle = style
            case .spinnerColor(let color):
                spinnerColor = color
            case .closeButton(let button):
                closeButton = button
            case .detailButton(let button):
                detailButton = button
            case .shareButton(let button):
                shareButton = button
            case .pagingMode(let mode):
                galleryPagingMode = mode
            case .headerViewLayout(let layout):
                headerLayout = layout
            case .footerViewLayout(let layout):
                footerLayout = layout
            case .closeLayout(let layout):
                closeLayout = layout
            case .detailLayout(let layout):
                detailLayout = layout
            case .shareLayout(let layout):
                shareLayout = layout
            case .statusBarHidden(let hidden):
                statusBarHidden = hidden
            case .hideDecorationViewsOnLaunch(let hidden):
                isDecorationViewsHidden = hidden
            }
        }
        
        self.presentTransition = GalleryPresentTransition(duration: presentTransitionDuration, displacedView: self.displacedView , decorationViewsHidden: isDecorationViewsHidden)
        self.closeTransition = GalleryCloseTransition(duration: dismissTransitionDuration)
        
        let options: [UIPageViewController.OptionsKey: Any] = [
            .interPageSpacing: NSNumber(value: dividerWidth)
        ]
        super.init(transitionStyle: UIPageViewController.TransitionStyle.scroll,
                   navigationOrientation: UIPageViewController.NavigationOrientation.horizontal,
                   options: options)
        
        self.imageControllerFactory = ImageViewControllerFactory(
            imageProvider: imageProvider,
            displacedView: displacedView,
            imageCount: imageCount,
            startIndex: startIndex,
            configuration: self.configuration,
            fadeInHandler: fadeInHandler,
            delegate: self)
        
        /// Needs to be kept alive with strong reference
        self.galleryDatasource = GalleryViewControllerDatasource(imageControllerFactory: imageControllerFactory, imageCount: imageCount, galleryPagingMode: galleryPagingMode)
        self.dataSource = galleryDatasource
        
        self.transitioningDelegate = self
        self.modalPresentationStyle = .custom
        self.extendedLayoutIncludesOpaqueBars = true
        self.applicationWindow?.windowLevel = (statusBarHidden) ? UIWindow.Level.statusBar + 1 : UIWindow.Level.normal
        
        configureInitialImageController()
        
        NotificationCenter.default.addObserver(self, selector: #selector(GalleryViewController.rotate), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        self.landedPageAtIndexCompletion?(self.currentIndex)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func applyOverlayView() -> UIView {
        
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black
        overlayView.bounds.size = UIScreen.main.bounds.insetBy(dx: -UIScreen.main.bounds.width * 2, dy: -UIScreen.main.bounds.height * 2).size
        overlayView.center = self.view.boundsCenter
        self.presentingViewController?.view.addSubview(overlayView)
        
        return overlayView
    }
    
    // MARK: - Animations
    
    @objc func rotate() {
        /// If the app supports rotation on global level, we don't need to rotate here manually because the rotation
        /// of key Window will rotate all app's content with it via affine transform and from the perspective of the
        /// gallery it is just a simple relayout. Allowing access to remaining code only makes sense if the app is 
        /// portrait only but we still want to support rotation inside the gallery.
        guard isPortraitOnly() else { return }
        
        guard UIDevice.current.orientation.isFlat == false &&
            isAnimating == false else { return }
        
        isAnimating = false
        
        let overlayView = applyOverlayView()
        
        if UIDevice.current.orientation.isLandscape{
            let footerFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.height, height: 100)
            footerView?.frame = footerFrame
            footerView?.layoutSubviews()
        }else if UIDevice.current.orientation.isPortrait{
            let footerFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100)
            footerView?.frame = footerFrame
            footerView?.layoutSubviews()
        }
        
        UIView.animate(withDuration: rotationAnimationDuration, delay: 0, options: UIView.AnimationOptions.curveLinear, animations: { [weak self] () -> Void in
            
            self?.view.transform = rotationTransform()
            self?.view.bounds = rotationAdjustedBounds()
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()
            
            })
        { [weak self] finished  in
            
            overlayView.removeFromSuperview()
            self?.isAnimating = false
        }
    }
    
    // MARK: - Configuration
    
    func configureInitialImageController() {
        
        let initialImageController = ImageViewController(
            imageProvider: imageProvider,
            configuration: configuration,
            imageCount: imageCount,
            displacedView: displacedView,
            startIndex: startIndex,
            imageIndex: startIndex,
            showDisplacedImage: true,
            fadeInHandler: fadeInHandler,
            delegate: self)
        self.setViewControllers([initialImageController], direction: UIPageViewController.NavigationDirection.forward, animated: false, completion: nil)
        initialImageController.view.isHidden = true
        
        self.presentTransition.completion = { [weak self] in
            initialImageController.view.isHidden = false
            
            self?.launchedCompletion?()
        }
    }
    
    fileprivate func configureCloseButton() {
        closeButton?.addTarget(self, action: #selector(GalleryViewController.close), for: .touchUpInside)
    }
    
    func createViewHierarchy() {
        if let close = closeButton {
            self.view.addSubview(close)
        }
    }
    
    func configureHeaderView() {
        if let header = headerView {
            self.view.addSubview(header)
        }
    }
    
    func configureFooterView() {
        if let footer = footerView {
            self.view.addSubview(footer)
        }
    }
    
    fileprivate func configureDetailButton() {
        detailButton?.addTarget(self, action: #selector(GalleryViewController.detail), for: .touchUpInside)
    }
    
    func createDetailViewHierarchy() {
        if let detail = detailButton {
            self.view.addSubview(detail)
        }
    }
    
    fileprivate func configureShareButton() {
        shareButton?.addTarget(self, action: #selector(GalleryViewController.action), for: .touchUpInside)
    }
    
    func createShareViewHierarchy() {
        
        if let share = shareButton {
            
            self.view.addSubview(share)
        }
    }
    
    func configurePresentTransition() {
        
        self.presentTransition.headerView = self.headerView
        self.presentTransition.footerView = self.footerView
        self.presentTransition.closeView = self.closeButton
        self.presentTransition.detailView = self.detailButton
        self.presentTransition.shareView = self.shareButton
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHeaderView()
        configureFooterView()
        configureCloseButton()
        configureDetailButton()
        configureShareButton()
        configurePresentTransition()
        createViewHierarchy()
        createDetailViewHierarchy()
        createShareViewHierarchy()
    }
    
    // MARK: - Layout
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        layoutCloseButton()
        layoutDetailButton()
        layoutShareButton()
        layoutHeaderView()
        layoutFooterView()
    }
    
    func layoutCloseButton() {
        
        guard let close = closeButton else { return }
        
        switch closeLayout {
            
        case .pinRight(let marginTop, let marginRight):
            
            close.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
            close.frame.origin.x = self.view.bounds.size.width - marginRight - close.bounds.size.width
            close.frame.origin.y = view.safeAreaInsets.top + marginTop
            
        case .pinLeft(let marginTop, let marginLeft):
            
            close.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
            close.frame.origin.x = marginLeft
            close.frame.origin.y = view.safeAreaInsets.top + marginTop
        }
    }
    
    func layoutDetailButton() {
        
        guard let detail = detailButton else { return }
        
        switch detailLayout {
            
        case .pinRight(let marginTop, let marginRight):
            
            detail.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
            detail.frame.origin.x = self.view.bounds.size.width - marginRight - detail.bounds.size.width
            detail.frame.origin.y = view.safeAreaInsets.top + marginTop
            
        case .pinLeft(let marginTop, let marginLeft):
            
            detail.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
            detail.frame.origin.x = marginLeft
            detail.frame.origin.y = view.safeAreaInsets.top + marginTop
        }
    }
    
    func layoutShareButton() {
        
        guard let share = shareButton else { return }
        
        switch shareLayout {
            
        case .pinRight(let marginTop, let marginRight):
            
            share.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
            share.frame.origin.x = self.view.bounds.size.width - marginRight - share.bounds.size.width
            share.frame.origin.y = view.safeAreaInsets.top + marginTop
            
        case .pinLeft(let marginTop, let marginLeft):
            
            share.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
            share.frame.origin.x = marginLeft
            share.frame.origin.y = view.safeAreaInsets.top + marginTop
        }
    }
    
    func layoutHeaderView() {
        
        guard let header = headerView else { return }
        
        switch headerLayout {
            
        case .center(let marginTop):
            
            header.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
            header.center = self.view.boundsCenter
            header.frame.origin.y = view.safeAreaInsets.top + marginTop
            
        case .pinBoth(let marginTop, let marginLeft,let marginRight):
            
            header.autoresizingMask = [.flexibleBottomMargin, .flexibleWidth]
            header.bounds.size.width = self.view.bounds.width - marginLeft - marginRight
            header.sizeToFit()
            header.frame.origin = CGPoint(x: marginLeft, y: view.safeAreaInsets.top + marginTop)
            
        case .pinLeft(let marginTop, let marginLeft):
            
            header.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
            header.frame.origin = CGPoint(x: marginLeft, y: view.safeAreaInsets.top + marginTop)
            
        case .pinRight(let marginTop, let marginRight):
            
            header.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
            header.frame.origin = CGPoint(x: self.view.bounds.width - marginRight - header.bounds.width, y: view.safeAreaInsets.top + marginTop)
        }
    }
    
    func layoutFooterView() {
        
        guard let footer = footerView else { return }
        
        switch footerLayout {
            
        case .center(let marginBottom):
            
            footer.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
            footer.center = self.view.boundsCenter
            footer.frame.origin.y = self.view.bounds.height - footer.bounds.height - view.safeAreaInsets.bottom - marginBottom
            
        case .pinBoth(let marginBottom, let marginLeft,let marginRight):
            
            footer.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
            footer.frame.size.width = self.view.bounds.width - marginLeft - marginRight
            footer.sizeToFit()
            footer.frame.origin = CGPoint(x: marginLeft, y: self.view.bounds.height - footer.bounds.height - view.safeAreaInsets.bottom - marginBottom)
            
        case .pinLeft(let marginBottom, let marginLeft):
            
            footer.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
            footer.frame.origin = CGPoint(x: marginLeft, y: self.view.bounds.height - footer.bounds.height - view.safeAreaInsets.bottom - marginBottom)
            
        case .pinRight(let marginBottom, let marginRight):
            
            footer.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]
            footer.frame.origin = CGPoint(x: self.view.bounds.width - marginRight - footer.bounds.width, y: self.view.bounds.height - footer.bounds.height - view.safeAreaInsets.bottom - marginBottom)
            
        }
    }
    
    // MARK: - Transitioning Delegate
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presentTransition
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
    
    // MARK: - Actions
    @objc func detail(){
        let detailsActivityViewController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
        }
        detailsActivityViewController.addAction(cancelAction)
        
        let OKAction = UIAlertAction(title: "View Item in NYPL Collection", style: .default) { UIAlertAction in
            let photoID = (self.imageProvider.locationData[self.currentIndex]["photoID"] as! String).components(separatedBy: "-").first
            
            let webURL = "http://digitalcollections.nypl.org/items/image_id/" + photoID!
            let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height-self.view.safeAreaInsets.bottom))
            if let url = URL(string: webURL) {
                let urlRequest = URLRequest(url: url)
                webView.load(urlRequest)
            }
            webView.tag = 69
            self.view.addSubview(webView)
            
            let navBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
            navBar.tag = 70
            self.view.addSubview(navBar)
            
            let navItem = UINavigationItem(title: "")
            let btn2 = UIButton()
            btn2.setImage(UIImage(named: "close_normal"), for: UIControl.State())
            btn2.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            btn2.imageEdgeInsets = UIEdgeInsets(top: -1.0, left: -30.0, bottom: 0.0, right: 0.0)
            btn2.addTarget(self, action: #selector(GalleryViewController.removeWebView), for: .touchUpInside)
            
            let item2 = UIBarButtonItem()
            item2.customView = btn2
            navItem.leftBarButtonItem = item2;
            navBar.setItems([navItem], animated: false);
            navBar.barTintColor = UIColor.black
        }
        detailsActivityViewController.addAction(OKAction)
        self.present(detailsActivityViewController, animated: true, completion: nil)
    }
    
    @objc func removeWebView(){
        if let viewWithTag = self.view.viewWithTag(69) {
            viewWithTag.removeFromSuperview()
        }
        if let viewWithTag = self.view.viewWithTag(70) {
            viewWithTag.removeFromSuperview()
        }
    }
    
    @objc func action(){
        let image = self.imageProvider.locationArray[self.currentIndex]
        let shareActivityViewController = UIActivityViewController(activityItems: [image!], applicationActivities: nil)
        self.present(shareActivityViewController, animated: true, completion: nil)
    }
    
    @objc func close() {
        UIView.animate(withDuration: 0.1, animations: { [weak self] in
            
            self?.headerView?.alpha = 0.0
            self?.footerView?.alpha = 0.0
            self?.closeButton?.alpha = 0.0
            self?.detailButton?.alpha = 0.0
            self?.shareButton?.alpha = 0.0
            
        }, completion: { [weak self] done in
            
//            if self?.currentIndex == self?.startIndex {
//                
//                self?.view.backgroundColor = UIColor.clearColor()
//                
//                if let imageController = self?.viewControllers?.first as? ImageViewController {
//                    
//                    imageController.closeAnimation(self?.closeAnimationDuration ?? 0.2, completion: { [weak self] finished in
//                        
//                        self?.innerClose()
//                        })
//                }
//            }
//            else {
                self?.innerClose()
//            }
            
        }) 
    }
    
    func innerClose() {
        
        self.modalTransitionStyle = .crossDissolve
        self.dismiss(animated: true) {
            
            self.applicationWindow!.windowLevel = UIWindow.Level.normal
        }
        
        closedCompletion?()
    }
    
    // MARK: - Image Controller Delegate
    
    func imageViewController(_ controller: ImageViewController, didSwipeToDismissWithDistanceToEdge distance: CGFloat) {
        
        self.view.backgroundColor = (distance == 0) ? UIColor.black : UIColor.clear
        
        if isDecorationViewsHidden == false {
            
            let alpha = 1 - distance * swipeToDismissFadeOutAccelerationFactor
            
            closeButton?.alpha = alpha
            detailButton?.alpha = alpha
            shareButton?.alpha = alpha
            headerView?.alpha = alpha
            footerView?.alpha = alpha
        }
    }
    
    func imageViewControllerDidSingleTap(_ controller: ImageViewController) {
        
        let alpha: CGFloat = (isDecorationViewsHidden) ? 1 : 0
        
        isDecorationViewsHidden = !isDecorationViewsHidden
        
        UIView.animate(withDuration: toggleHeaderFooterAnimationDuration, animations: { [weak self] in
            
            self?.headerView?.alpha = alpha
            self?.footerView?.alpha = alpha
            self?.closeButton?.alpha = alpha
            self?.detailButton?.alpha = alpha
            self?.shareButton?.alpha = alpha
            
            })
    }
    
    func imageViewControllerDidAppear(_ controller: ImageViewController) {
        
        self.currentIndex = controller.index
        self.landedPageAtIndexCompletion?(self.currentIndex)
    }
    override public var prefersStatusBarHidden : Bool {
        return true
    }
}
