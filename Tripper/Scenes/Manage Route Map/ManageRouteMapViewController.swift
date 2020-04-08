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
    func displayFetchNewAnnotationsInfo(viewModel: ManageRouteMap.FetchNewAnnotationsInfo.ViewModel)
    func displayCreateRoutePoint(viewModel: ManageRouteMap.CreateRoutePoint.ViewModel)
    func displaySetRoutePoint(viewModel: ManageRouteMap.SetRoutePoint.ViewModel)
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
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    // MARK: Routing
//    struct SeguesIdentifiers {
//        /// You should assign RoutePoint object as sender to this segue.
//        static let showAnnotationDetail = "ShowAnnotationDetail"
//        /// You should assign RoutePoint object as sender to this segue.
//        static let showAnnotationEdit = "ShowAnnotationEdit"
//        static let showRouteList = "ShowRouteList"
//    }
    
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
        reloadAnnotationsData()
        // TODO: Refetch data to check is there new ones.
    }
    
    private func reloadAnnotationsData() {
        let request = ManageRouteMap.FetchNewAnnotationsInfo.Request()
        interactor?.fetchNewAnnotationsInfo(request: request)
    }
    
    // MARK: Create Route Point
    
    func displayCreateRoutePoint(viewModel: ManageRouteMap.CreateRoutePoint.ViewModel) {
//        let annotationInfo = ManageRouteMap.ConcreteAnnotationInfo(
//            id: viewModel.id, latitude: viewModel.latitude, longitude: viewModel.longitude)
//        setAnnotation(annotationInfo: annotationInfo)
        router?.routeToCreateRoutePoint(segue: nil)
    }
    
    // MARK: Set Route Point
    
    func displaySetRoutePoint(viewModel: ManageRouteMap.SetRoutePoint.ViewModel) {
        setAnnotation(annotationInfo: viewModel.annotationInfo)
    }
    
    // MARK: Fetch new annotations info
    func displayFetchNewAnnotationsInfo(viewModel: ManageRouteMap.FetchNewAnnotationsInfo.ViewModel) {
        
    }
    
}

extension ManageRouteMapViewController: MGLMapViewDelegate {
    
    // MARK: - Map View's Delegates
    
    @objc func handleMapLongPress(sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        
        let longPressedPoint: CGPoint = sender.location(in: mapView)
        let coordinate: CLLocationCoordinate2D = mapView.convert(longPressedPoint, toCoordinateFrom: mapView)
        
        print("*** Long pressed on the map.")
        
        let request = ManageRouteMap.CreateRoutePoint.Request(latitude: coordinate.latitude, longitude: coordinate.longitude)
        interactor?.createRoutePoint(request: request)
//        performSegue(withIdentifier: SeguesIdentifiers.showAnnotationEdit, sender: nil)
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
