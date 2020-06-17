//
//  ManageRouteMapViewController.swift
//  Tripper
//
//  Created by Denis Cherniy on 07.04.2020.
//  Copyright (c) 2020 Denis Cherniy. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit
import Mapbox
import Swinject

protocol ManageRouteMapDisplayLogic: class {
    func displayDataSetup(viewModel: ManageRouteMap.SetupData.ViewModel)
    func displayFetchDifference(viewModel: ManageRouteMap.FetchDifference.ViewModel)
    func displayCreateRoutePoint(viewModel: ManageRouteMap.CreateRoutePoint.ViewModel)
    func displaySetRoutePoint(viewModel: ManageRouteMap.SetRoutePoint.ViewModel)
    func displaySelectAnnotation(viewModel: ManageRouteMap.SelectAnnotation.ViewModel)
    func displayDeselectAnnotation(viewModel: ManageRouteMap.DeselectAnnotation.ViewModel)
    func displayShowDetail(viewModel: ManageRouteMap.ShowDetail.ViewModel)
    func displayEditRoutePoint(viewModel: ManageRouteMap.EditRoutePoint.ViewModel)
    func displayDeleteRoutePoint(viewModel: ManageRouteMap.DeleteAnnotation.ViewModel)
    func displayCreateRouteFragment(viewModel: ManageRouteMap.CreateRouteFragment.ViewModel)
    func displayAddRouteFragment(viewModel: ManageRouteMap.AddRouteFragment.ViewModel)
    func displayDeleteRouteFragment(viewModel: ManageRouteMap.DeleteRouteFragment.ViewModel)
    func displayMapRoute(viewModel: ManageRouteMap.MapRoute.ViewModel)
    func displayClearAll(viewModel: ManageRouteMap.ClearAll.ViewModel)
    func displayToggleUserInput(viewModel: ManageRouteMap.ToggleUserInput.ViewModel)
    func displayFocus(viewModel: ManageRouteMap.Focus.ViewModel)
    func displayFocusOnRoute(viewModel: ManageRouteMap.FocusOnRoute.ViewModel)
    func displayFocusOnUser(viewModel: ManageRouteMap.FocusOnUser.ViewModel)
    func displayFocusOnCoordinates(viewModel: ManageRouteMap.FocusOnCoordinates.ViewModel)
    func displayRouteEstimation(viewModel: ManageRouteMap.RouteEstimation.ViewModel)
}

protocol HasFocusableMap: class {
    func focusableMap(didSelected coordinates: [CLLocationCoordinate2D])
}

class ManageRouteMapViewController: UIViewController, ManageRouteMapDisplayLogic {
    var interactor: ManageRouteMapBusinessLogic?
    var router: (NSObjectProtocol & ManageRouteMapRoutingLogic & ManageRouteMapDataPassing)?
    
    private let zoomLevel = 10.0
    
    private var interactionController: UIPercentDrivenInteractiveTransition?
    
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var userInteractionView: UIView!
    
    var detailsPopup: Popup? {
        didSet {
            if detailsPopup == nil {
                deselectAnnotation()
                fetchDifference()
            } else {
                focusOnRoute(nil)
            }
        }
    }
    
    weak var fastNavigationPopup: SidePopup?
    
    var annotationsID: Dictionary<MGLPointAnnotation, String> = Dictionary()
    private var isLoaded: Bool = false
    
    // MARK: Object lifecycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: Setup
    
    private func setup() {
        let viewController = self
        let interactor = ManageRouteMapInteractor()
        let presenter = ManageRouteMapPresenter()
        let router = ManageRouteMapRouter()
        let worker = ManageRouteMapWorker(routePointGateway: Container.shared.resolve(RoutePointGateway.self)!,
                                          routeFragmentGateway: Container.shared.resolve(RouteFragmentGateway.self)!)
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        interactor.worker = worker
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    // MARK: - Routing
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let scene = segue.identifier {
            let selector = NSSelectorFromString("routeTo\(scene)WithSegue:")
            if let router = router, router.responds(to: selector) {
                router.perform(selector, with: segue)
            }
        }
    }
    
    // MARK: Route Navigation
    
    @IBAction func routeButtonTapped(_ sender: Any) {
        if let popup = fastNavigationPopup {
            popup.dismissPopup()
        } else {
            detailsPopup?.dismissPopup()
            router?.routeToFastNavigation(segue: nil)
            focusOnRoute(nil)
        }
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerGestureRecognizers()
        configureDelegates()
        configureAppearance()
    }
    
    private func registerGestureRecognizers() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress(sender:)))
        
        for recognizer in mapView.gestureRecognizers! where recognizer is UILongPressGestureRecognizer {
            longPressGestureRecognizer.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    private func configureDelegates() {
        mapView.delegate = self
    }
    
    private func configureAppearance() {
        routeEstimationView.layer.cornerRadius = 16
        userInteractionView.layer.cornerRadius = 32
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isLoaded {
            fetchDifference()
        }
    }
    
    // MARK: - Setup Data
    
    func setupData() {
        let request = ManageRouteMap.SetupData.Request()
        interactor?.setupData(request: request)
    }
    
    func displayDataSetup(viewModel: ManageRouteMap.SetupData.ViewModel) {
        toggleUserInput(isLocked: true)
        
        for annotationInfo in viewModel.annotationsInfo {
            let request = ManageRouteMap.SetRoutePoint.Request(annotationInfo: annotationInfo)
            interactor?.setRoutePoint(request: request)
        }
        
        for routeFragment in viewModel.routeFragments {
            let request = ManageRouteMap.AddRouteFragment.Request(routeFragment: routeFragment)
            interactor?.addRouteFragment(request: request)
        }
        
        toggleUserInput(isLocked: false)
        
        if viewModel.routeFragments.count > 0 {
            routeEstimation()
        }
        
        isLoaded = true
    }
    
    // MARK: Create Route Point
    
    func createRoutePoint(at coordinate: CLLocationCoordinate2D) {
        let requestToToggle = ManageRouteMap.ToggleUserInput.Request(isLocked: true)
        interactor?.toggleUserInput(request: requestToToggle)
        
        let requestToCreate = ManageRouteMap.CreateRoutePoint.Request(latitude: coordinate.latitude, longitude: coordinate.longitude)
        interactor?.createRoutePoint(request: requestToCreate)
    }
    
    func displayCreateRoutePoint(viewModel: ManageRouteMap.CreateRoutePoint.ViewModel) {
        // To be sure that it's displaced because if Route Point Creation is cancelled Spinner stays there.
        let requestToToggle = ManageRouteMap.ToggleUserInput.Request(isLocked: false)
        interactor?.toggleUserInput(request: requestToToggle)
        
        if viewModel.isSucceed {
            detailsPopup?.dismissPopup()
            fastNavigationPopup?.dismissPopup()
            router?.routeToCreateRoutePoint(segue: nil)
        } else {
            showCreationFailure(title: "Route Creation Error!", message: "Route between last an new point can't be calculated.")
        }
        
    }
    
    // MARK: Set Route Point
    
    func displaySetRoutePoint(viewModel: ManageRouteMap.SetRoutePoint.ViewModel) {
        setAnnotation(annotationInfo: viewModel.annotationInfo)
    }
    
    // MARK: Fetch Difference
    
    func fetchDifference() {
        let request = ManageRouteMap.FetchDifference.Request()
        interactor?.fetchDifference(request: request)
    }
    
    func displayFetchDifference(viewModel: ManageRouteMap.FetchDifference.ViewModel) {
        for annotationInfo in viewModel.newAnnotationsInfo {
            let requestToSetRP = ManageRouteMap.SetRoutePoint.Request(annotationInfo: annotationInfo)
            interactor?.setRoutePoint(request: requestToSetRP)
        }
        
        for annotationInfo in viewModel.removedAnnotationsInfo {
            let identifier = annotationInfo.id
            let requestToDeleteRP = ManageRouteMap.DeleteAnnotation.Request(identifier: identifier)
            interactor?.deleteRoutePoint(request: requestToDeleteRP)
        }
        
        if viewModel.newAnnotationsInfo.count > 0 || viewModel.removedAnnotationsInfo.count > 0 {
            let request = ManageRouteMap.MapRoute.Request(addedAnnotationsInfo: viewModel.newAnnotationsInfo,
                                                          removedAnnotationsInfo: viewModel.removedAnnotationsInfo)
            interactor?.mapRoute(request: request)
        }
    }
    
    // MARK: Select Annotation
    
    func displaySelectAnnotation(viewModel: ManageRouteMap.SelectAnnotation.ViewModel) {
        if viewModel.identifier != nil {
            showDetail()
            
            interactor?.focusOnCoordinates(request: .init(coordinates: [viewModel.coordinate]))
        }
    }
    
    // MARK: Deselect Annotation
    
    func deselectAnnotation() {
        let request = ManageRouteMap.DeselectAnnotation.Request()
        interactor?.deselectAnnotation(request: request)
    }
    
    func displayDeselectAnnotation(viewModel: ManageRouteMap.DeselectAnnotation.ViewModel) {
        let selectedAnnotation = mapView.selectedAnnotations.first
        if let annotation = selectedAnnotation {
            mapView.deselectAnnotation(annotation, animated: true)
        }
        
    }
    
    // MARK: Show Detail
    
    func showDetail() {
        let request = ManageRouteMap.ShowDetail.Request()
        interactor?.showDetail(request: request)
    }
    
    func displayShowDetail(viewModel: ManageRouteMap.ShowDetail.ViewModel) {
        fastNavigationPopup?.dismissPopup()
        router?.routeToDetailRoutePoint(segue: nil)
    }
    
    // MARK: Edit Route Point
    
    func editSelectedRoutePoint() {
        let request = ManageRouteMap.EditRoutePoint.Request()
        interactor?.editRoutePoint(request: request)
    }
    
    func displayEditRoutePoint(viewModel: ManageRouteMap.EditRoutePoint.ViewModel) {
        router?.routeToEditRoutePoint(segue: nil)
    }
    
    // MARK: Delete Route Point
    
    func displayDeleteRoutePoint(viewModel: ManageRouteMap.DeleteAnnotation.ViewModel) {
        for (annotation, id) in annotationsID {
            if id == viewModel.identifier {
                mapView.removeAnnotation(annotation)
                annotationsID.removeValue(forKey: annotation)
            }
        }
    }
    
    // MARK: Create Route Fragment
    
    func displayCreateRouteFragment(viewModel: ManageRouteMap.CreateRouteFragment.ViewModel) {
        let request = ManageRouteMap.AddRouteFragment.Request(routeFragment: viewModel.routeFragment)
        interactor?.addRouteFragment(request: request)
        
        routeFragmentsToProcess -= 1
        
        routeEstimation()
    }
    
    // MARK: Add Route Fragment
    
    func displayAddRouteFragment(viewModel: ManageRouteMap.AddRouteFragment.ViewModel) {
        let routeCoordinates = viewModel.routeFragment.coordinates
        let identifier = viewModel.routeFragment.identifier
        guard routeCoordinates.count > 0 else { return }
        
        let polyline = MGLPolylineFeature(coordinates: routeCoordinates, count: UInt(routeCoordinates.count))
        
        let source = MGLShapeSource(identifier: identifier, features: [polyline], options: nil)
        
        // Customize the route line color and width
        let lineStyle = MGLLineStyleLayer(identifier: identifier, source: source)
        lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1))
        lineStyle.lineWidth = NSExpression(forConstantValue: 3)
        
        mapView.style?.addSource(source)
        mapView.style?.addLayer(lineStyle)
    }
    
    // MARK: Error Handling
    
    func showCreationFailure(title: String = "Error", message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(alertAction)
        showDetailViewController(alertController, sender: nil)
    }
    
    // MARK: Delete Route Fragment
    
    func displayDeleteRouteFragment(viewModel: ManageRouteMap.DeleteRouteFragment.ViewModel) {
        if let sources = mapView.style?.sources {
            for source in sources {
                if source.identifier == viewModel.identifier {
                    mapView.style!.removeSource(source)
                    break
                }
            }
        }
        
        if let layer = mapView.style?.layer(withIdentifier: viewModel.identifier) {
            mapView.style!.removeLayer(layer)
        }
        
        routeFragmentsToProcess -= 1
        
        routeEstimation()
    }
    
    // MARK: Map Route
    
    private var routeFragmentsToProcess = 0 {
        didSet {
            if routeFragmentsToProcess == 0 {
                toggleUserInput(isLocked: false)
            }
        }
    }
    
    func displayMapRoute(viewModel: ManageRouteMap.MapRoute.ViewModel) {
        routeFragmentsToProcess = viewModel.idsOfDeletedRouteFragments.count + viewModel.addedSubroutesInfo.count
        if routeFragmentsToProcess > 0 {
            toggleUserInput(isLocked: true)
        }
        
        if viewModel.idsOfDeletedRouteFragments.count > 0 {
            for id in viewModel.idsOfDeletedRouteFragments {
                let request = ManageRouteMap.DeleteRouteFragment.Request(identifier: id)
                interactor?.deleteRouteFragment(request: request)
            }
        }
        
        if viewModel.addedSubroutesInfo.count > 0 {
            for subrouteInfo in viewModel.addedSubroutesInfo {
                let request = ManageRouteMap.CreateRouteFragment.Request(addedSubrouteInfo: subrouteInfo)
                interactor?.createRouteFragment(request: request)
            }
        }
    }
    
    // MARK: Clear All
    
    @IBAction func clearAll() {
        let request = ManageRouteMap.ClearAll.Request()
        interactor?.clearAll(request: request)
    }
    
    func displayClearAll(viewModel: ManageRouteMap.ClearAll.ViewModel) {
        fetchDifference()
        detailsPopup?.dismissPopup()
        fastNavigationPopup?.dismissPopup()
    }
    
    // MARK: Toggle User Input
    
    @IBOutlet weak var clearAllBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var toRouteBarButtonItem: UIBarButtonItem!
    
    private lazy var dimmingView = { () -> UIView in
        let dimmingView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height))
        
        // Blur Effect
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = dimmingView.bounds
        dimmingView.addSubview(blurEffectView)
        
        return dimmingView
    }()
    
    func toggleUserInput(isLocked: Bool) {
        let request = ManageRouteMap.ToggleUserInput.Request(isLocked: isLocked)
        interactor?.toggleUserInput(request: request)
    }
    
    func displayToggleUserInput(viewModel: ManageRouteMap.ToggleUserInput.ViewModel) {
        if viewModel.isLocked {
            lockUserInput()
        } else {
            unlockUserInput()
            
        }
    }
    
    private func lockUserInput() {
        showSpinner()
        clearAllBarButtonItem.isEnabled = false
        toRouteBarButtonItem.isEnabled = false
    }
    
    private func showSpinner() {
        let spinner = UIActivityIndicatorView(style: .gray)
        spinner.center = CGPoint(x: dimmingView.bounds.midX + 0.5, y: dimmingView.bounds.midY + 0.5)
        spinner.tag = 1000
        dimmingView.addSubview(spinner)
        
        
        view.addSubview(dimmingView)
        spinner.startAnimating()
    }
    
    private func unlockUserInput() {
        hideSpinner()
        clearAllBarButtonItem.isEnabled = true
        toRouteBarButtonItem.isEnabled = true
    }
    
    private func hideSpinner() {
        dimmingView.removeFromSuperview()
    }
    
    // MARK: Focus
    
    private func focus() {
        interactor?.focus(request: .init())
    }
    
    func displayFocus(viewModel: ManageRouteMap.Focus.ViewModel) {
        if viewModel.routeExists {
            interactor?.focusOnRoute(request: .init())
        } else {
            focusOnUser()
        }
    }
    
    // MARK: Focus On Route
    
    @IBAction func focusOnRoute(_ sender: UIButton?) {
        if let button = sender {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                button.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }, completion: { _ in
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                    button.transform = CGAffineTransform.identity
                })
            })
        }
        
        let request = ManageRouteMap.FocusOnRoute.Request()
        interactor?.focusOnRoute(request: request)
    }
    
    func displayFocusOnRoute(viewModel: ManageRouteMap.FocusOnRoute.ViewModel) {
        focusOn(swCoord: viewModel.southWestCoordinate, neCoord: viewModel.northEastCoordinate)
    }
    
    // MARK: Focus On User
    
    @IBAction func focusOnUser(_ sender: UIButton?) {
        if let button = sender {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                button.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }, completion: { _ in
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                    button.transform = CGAffineTransform.identity
                })
            })
        }
        
        focusOnUser()
    }
    
    private func focusOnUser() {
        if let userCoordinate = mapView.userLocation?.coordinate {
            interactor?.focusOnUser(request: .init(userCoordinate: userCoordinate))
        }
    }
    
    func displayFocusOnUser(viewModel: ManageRouteMap.FocusOnUser.ViewModel) {
        interactor?.focusOnCoordinates(request: .init(coordinates: [viewModel.userCoordinate]))
        detailsPopup?.dismissPopup()
    }
    
    // MARK: Focus On Coordinates
    
    func displayFocusOnCoordinates(viewModel: ManageRouteMap.FocusOnCoordinates.ViewModel) {
        focusOn(swCoord: viewModel.southWestCoordinate, neCoord: viewModel.northEastCoordinate)
    }
    
    // MARK: Route Estimation
    
    @IBOutlet weak var routeEstimationView: UIView!
    @IBOutlet weak var routeLengthLabel: UILabel!
    @IBOutlet weak var routeTimeLabel: UILabel!
    
    func routeEstimation() {
        let request = ManageRouteMap.RouteEstimation.Request()
        interactor?.routeEstimation(request: request)
    }
    
    func displayRouteEstimation(viewModel: ManageRouteMap.RouteEstimation.ViewModel) {
        if viewModel.toShow {
            routeLengthLabel.text = viewModel.distanceEstimation
            routeTimeLabel.text = viewModel.timeEstimation
            
            if routeEstimationView.isHidden {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                    self.routeEstimationView.alpha = 1
                }, completion: { _ in
                    self.routeEstimationView.isHidden = false
                })
            }
            
        } else {
            if !routeEstimationView.isHidden {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                   self.routeEstimationView.alpha = 0
                }, completion: { _ in
                    self.routeEstimationView.isHidden = true
                    self.routeLengthLabel.text = ""
                    self.routeTimeLabel.text = ""
                })
            }
        }
        
    }
    
    // MARK: - Shared Helper Methods
    
    private func getIDOfSelectedRoutePoint() -> String? {
        let selectedAnnotation = mapView.selectedAnnotations.first
        if let annotation = selectedAnnotation {
            let idOfSelectedRP = annotationsID[annotation as! MGLPointAnnotation]
            
            return idOfSelectedRP
        }
        
        return nil
    }
    
    private func checkInProcessedRouteFragment() {
        if routeFragmentsToProcess > 0 {
            routeFragmentsToProcess -= 1
            
            routeEstimation()
        } else {
            fatalError("*** There are route points that are not counted in routeFragmentsToProcess!")
        }
    }
    
    private func focusOn(swCoord: CLLocationCoordinate2D, neCoord: CLLocationCoordinate2D) {
        if neCoord != swCoord {
            let offset = CGFloat(60)
            let topOffset = offset + navigationController!.navigationBar.frame.height
            var bottomOffset = offset
            var rightSideOffset = offset
            
            
            if let popup = detailsPopup {
                bottomOffset += CGFloat(popup.state.rawValue) * view.frame.height
            }
            
            if let popup = fastNavigationPopup {
                rightSideOffset += popup.width
            }
            
            let camera = mapView.cameraThatFitsCoordinateBounds(MGLCoordinateBounds(sw: swCoord, ne: neCoord), edgePadding: UIEdgeInsets(top: topOffset, left: offset, bottom: bottomOffset, right: rightSideOffset))
            
            mapView.setCamera(camera, animated: true)
        } else { // Just one point
            mapView.setCenter(neCoord, zoomLevel: zoomLevel, animated: true)
        }
    }
}

extension ManageRouteMapViewController: MGLMapViewDelegate {
    
    // MARK: - Map View's Delegates
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        let identifierOfSelectedAnnotation = annotationsID[annotation as! MGLPointAnnotation]
        // Pass optional value if it's nil show error in presenter.
        let request = ManageRouteMap.SelectAnnotation.Request(identifier: identifierOfSelectedAnnotation, coordinate: annotation.coordinate)
        
        interactor?.selectAnnotation(request: request)
    }
        
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        setupData()
        focus()
    }
    
    // MARK: Gesture Handlers
    
    @objc func handleMapLongPress(sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        
        let longPressedPoint: CGPoint = sender.location(in: mapView)
        let coordinate: CLLocationCoordinate2D = mapView.convert(longPressedPoint, toCoordinateFrom: mapView)
        
        let requestToSelect = ManageRouteMap.SelectAnnotation.Request(identifier: nil, coordinate: coordinate)
        interactor?.selectAnnotation(request: requestToSelect)
        
        createRoutePoint(at: coordinate)
    }
    
    // MARK: - Helper Methods
    
    private func setAnnotation(annotationInfo: AnnotationInfo) {
        let annotation = MGLPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: annotationInfo.latitude, longitude: annotationInfo.longitude)
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        annotationsID[annotation] = annotationInfo.id
    }
}

extension ManageRouteMapViewController: HasFocusableMap {
    func focusableMap(didSelected coordinates: [CLLocationCoordinate2D]) {
        interactor?.focusOnCoordinates(request: .init(coordinates: coordinates))
    }
}
