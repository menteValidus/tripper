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

protocol ManageRouteMapDisplayLogic: class {
    func displayFetchDifference(viewModel: ManageRouteMap.FetchDifference.ViewModel)
    func displayCreateRoutePoint(viewModel: ManageRouteMap.CreateRoutePoint.ViewModel)
    func displaySetRoutePoint(viewModel: ManageRouteMap.SetRoutePoint.ViewModel)
    func displaySelectAnnotation(viewModel: ManageRouteMap.SelectAnnotation.ViewModel)
    func displayDeselectAnnotation(viewModel: ManageRouteMap.DeselectAnnotation.ViewModel)
    func displayShowDetail(viewModel: ManageRouteMap.ShowDetail.ViewModel)
    func displayEditRoutePoint(viewModel: ManageRouteMap.EditRoutePoint.ViewModel)
    func displayDeleteRoutePoint(viewModel: ManageRouteMap.DeleteAnnotation.ViewModel)
    func displayCreateRouteFragment(viewModel: ManageRouteMap.CreateRouteFragment.ViewModel)
    func displayDeleteRouteFragment(viewModel: ManageRouteMap.DeleteRouteFragment.ViewModel)
    func displayMapRoute(viewModel: ManageRouteMap.MapRoute.ViewModel)
    func displayClearAll(viewModel: ManageRouteMap.ClearAll.ViewModel)
    func displayToggleUserInput(viewModel: ManageRouteMap.ToggleUserInput.ViewModel)
    func displayFocus(viewModel: ManageRouteMap.Focus.ViewModel)
    func displayFocusOnUser(viewModel: ManageRouteMap.FocusOnUser.ViewModel)
}

class ManageRouteMapViewController: UIViewController, ManageRouteMapDisplayLogic {
    var interactor: ManageRouteMapBusinessLogic?
    var router: (NSObjectProtocol & ManageRouteMapRoutingLogic & ManageRouteMapDataPassing)?
    
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var routeEstimationView: UIView!
    @IBOutlet weak var routeLengthLabel: UILabel!
    @IBOutlet weak var routeTimeLabel: UILabel!
    @IBOutlet weak var clearAllBarItem: UIBarButtonItem!
    @IBOutlet weak var routeListBarItem: UIBarButtonItem!
    
    var popup: Popup? {
        didSet {
            if popup == nil {
                fetchDifference()
            }
        }
    }
    
    var annotationsID: Dictionary<MGLPointAnnotation, String> = Dictionary()
    
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
        let worker = ManageRouteMapWorker()
        let routeCreator = MapboxRouteCreator()
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        interactor.worker = worker
        interactor.routeCreator = routeCreator
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    // MARK: Routing
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let scene = segue.identifier {
            let selector = NSSelectorFromString("routeTo\(scene)WithSegue:")
            if let router = router, router.responds(to: selector) {
                router.perform(selector, with: segue)
            }
        }
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerGestureRecognizers()
        mapView.delegate = self
//        mapView.userTrackingMode = MGLUserTrackingMode.follow
    }
    
    private func registerGestureRecognizers() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress(sender:)))
        
        for recognizer in mapView.gestureRecognizers! where recognizer is UILongPressGestureRecognizer {
            longPressGestureRecognizer.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchDifference()
    }
    
    // MARK: Create Route Point
    
    func createRoutePoint(at coordinate: CLLocationCoordinate2D) {
        // TODO: If creation of Route Point is cancelled Spinner will be here forever.
        let requestToToggle = ManageRouteMap.ToggleUserInput.Request(isLocked: true)
        interactor?.toggleUserInput(request: requestToToggle)
        
        let requestToCreate = ManageRouteMap.CreateRoutePoint.Request(latitude: coordinate.latitude, longitude: coordinate.longitude)
        interactor?.createRoutePoint(request: requestToCreate)
    }
    
    func displayCreateRoutePoint(viewModel: ManageRouteMap.CreateRoutePoint.ViewModel) {
        // To be sure that it's displaced because if Route Point Creation is cancelled Spinner stays there.
        let requestToToggle = ManageRouteMap.ToggleUserInput.Request(isLocked: false)
        interactor?.toggleUserInput(request: requestToToggle)
        
        popup?.dismissPopup()
        router?.routeToCreateRoutePoint(segue: nil)
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
            let requestToSetRP = ManageRouteMap.SetRoutePoint.Request(annotationsInfo: annotationInfo)
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
        }
    }
    
    // MARK: Deselect Annotation
    
    func deselectAnnotations() {
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
        
        routeFragmentsToProcess -= 1
    }
    
    // MARK: Delete Route Fragment
    
    func displayDeleteRouteFragment(viewModel: ManageRouteMap.DeleteRouteFragment.ViewModel) {
        if let sources = mapView.style?.sources {
            for source in sources {
                if source.identifier == viewModel.identifier {
                    mapView.style!.removeSource(source)
                }
            }
        }
        
        if let layer = mapView.style?.layer(withIdentifier: viewModel.identifier) {
            mapView.style!.removeLayer(layer)
        }
        
        routeFragmentsToProcess -= 1
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
        popup?.dismissPopup()
    }
    
    // MARK: Toggle User Input
    
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
            // Lock all user input
            showSpinner()
        } else {
            // Unlock
            hideSpinner()
        }
    }
    
    private func showSpinner() {
        let spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner.center = CGPoint(x: dimmingView.bounds.midX + 0.5, y: dimmingView.bounds.midY + 0.5)
        spinner.tag = 1000
        dimmingView.addSubview(spinner)
        
        
        view.addSubview(dimmingView)
        spinner.startAnimating()
    }
    
    private func hideSpinner() {
        dimmingView.removeFromSuperview()
        focusOnRoute(nil)
    }
    
    // MARK: Focus
    
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
        
        let request = ManageRouteMap.Focus.Request()
        interactor?.focus(request: request)
    }
    
    func displayFocus(viewModel: ManageRouteMap.Focus.ViewModel) {
        let offset = CGFloat(60)
        let camera = mapView.cameraThatFitsCoordinateBounds(MGLCoordinateBounds(sw: viewModel.southWestCoordinate, ne: viewModel.northEastCoordinate), edgePadding: UIEdgeInsets(top: 20.0, left: offset, bottom: offset, right: offset))
        
        mapView.setCamera(camera, animated: true)
    }
    
    // MARK: Focus On User
    
    @IBAction func focusOnUser(_ sender: UIButton?) {
        if let userCoordinate = mapView.userLocation?.coordinate {
            if let button = sender {
//                let newScale = button.transform.scaledBy(x: 1.2, y: 1.2)
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                    button.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                        button.transform = CGAffineTransform.identity
                    })
                })
            }
            let request = ManageRouteMap.FocusOnUser.Request(userCoordinate: userCoordinate)
            interactor?.focusOnUser(request: request)
        }
    }
    
    func displayFocusOnUser(viewModel: ManageRouteMap.FocusOnUser.ViewModel) {
        let zoomLevel = 6.0
        mapView.setCenter(viewModel.userCoordinate, zoomLevel: zoomLevel, animated: true)
    }
    
    // MARK: Shared Helper Methods
    
    private func getIDOfSelectedRoutePoint() -> String? {
        let selectedAnnotation = mapView.selectedAnnotations.first
        if let annotation = selectedAnnotation {
            let idOfSelectedRP = annotationsID[annotation as! MGLPointAnnotation]
            
            return idOfSelectedRP
        }
        
        return nil
    }
}

extension ManageRouteMapViewController: MGLMapViewDelegate {
    
    // MARK: - Map View's Delegates
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        let identifierOfSelectedAnnotation = annotationsID[annotation as! MGLPointAnnotation]
        // Pass optional value if it's nil show error in presenter.
        let request = ManageRouteMap.SelectAnnotation.Request(identifier: identifierOfSelectedAnnotation)
        
        interactor?.selectAnnotation(request: request)
    }
    
    // MARK: Gesture Handlers
    
    @objc func handleMapLongPress(sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        
        let longPressedPoint: CGPoint = sender.location(in: mapView)
        let coordinate: CLLocationCoordinate2D = mapView.convert(longPressedPoint, toCoordinateFrom: mapView)
        
        print("*** Long pressed on the map.")
        
        let requestToDeselect = ManageRouteMap.SelectAnnotation.Request(identifier: nil)
        interactor?.selectAnnotation(request: requestToDeselect)
        
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
