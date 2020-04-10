//
//  ManageRouteMapInteractor.swift
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
import CoreLocation

protocol ManageRouteMapBusinessLogic {
    func fetchNewAnnotationsInfo(request: ManageRouteMap.FetchNewAnnotationsInfo.Request)
    func createRoutePoint(request: ManageRouteMap.CreateRoutePoint.Request)
    func setRoutePoint(request: ManageRouteMap.SetRoutePoint.Request)
    func selectAnnotation(request: ManageRouteMap.SelectAnnotation.Request)
//    func deselectAnnotation(request)
}

protocol ManageRouteMapDataStore {
    var tappedCoordinate: CLLocationCoordinate2D? { get set }
    var idOfSelectedAnnotation: String? { get set }
    var selectedRoutePoint: RoutePoint? { get set }
    var popup: Popup? { get set }
}

class ManageRouteMapInteractor: ManageRouteMapBusinessLogic, ManageRouteMapDataStore {
    var presenter: ManageRouteMapPresentationLogic?
    var worker: ManageRouteMapWorker?
    var popup: Popup?
    
//    var idGenerator: IDGenerator
    
    var annotationsInfo: [AnnotationInfo]
    var idOfSelectedAnnotation: String?
    
    var selectedRoutePoint: RoutePoint? {
        get {
            
            // TODO: Unreliable implementation.
            if let id = idOfSelectedAnnotation {
                return worker?.fetchRoutePoint(with: id)
//                let selectedAnnotation = annotationsInfo.first(where: {
//                    return $0.id == id
//                })
//
//                return selectedAnnotation as? RoutePoint
            } else {
                return nil
            }
        }
        
        set {
            idOfSelectedAnnotation = newValue?.id
        }
    }
    
    init() {
        annotationsInfo = []
//        idGenerator = NSUUIDGenerator.instance
    }
    
    // MARK: Create route point
    
    var tappedCoordinate: CLLocationCoordinate2D?
    
    func createRoutePoint(request: ManageRouteMap.CreateRoutePoint.Request) {
        popup?.dismissPopup()
        
        tappedCoordinate = CLLocationCoordinate2D(latitude: request.latitude, longitude: request.longitude)
        let response = ManageRouteMap.CreateRoutePoint.Response()
        presenter?.presentAnnotationCreation(response: response)
    }
    
    // MARK: Fetch new annotations info
    
    func fetchNewAnnotationsInfo(request: ManageRouteMap.FetchNewAnnotationsInfo.Request) {
        annotationsInfo = worker?.fetchNewAnnotationsInfo() ?? []
        let response = ManageRouteMap.FetchNewAnnotationsInfo.Response(annotationsInfo: annotationsInfo as! [ManageRouteMap.ConcreteAnnotationInfo])
        
        presenter?.presentFetchNewAnnotationsInfo(response: response)
    }
    
    // MARK: Set route point
    
    func setRoutePoint(request: ManageRouteMap.SetRoutePoint.Request) {
        let response = ManageRouteMap.SetRoutePoint.Response(annotationInfo: request.annotationsInfo)
        presenter?.presentSetRoutePoint(response: response)
    }
    
    // MARK: Select Annotation
    
    func selectAnnotation(request: ManageRouteMap.SelectAnnotation.Request) {
        idOfSelectedAnnotation = request.identifier
        let response = ManageRouteMap.SelectAnnotation.Response(identifier: idOfSelectedAnnotation)
        presenter?.presentSelectAnnotation(response: response)
    }
}
