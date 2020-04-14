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
    func deselectAnnotation(request: ManageRouteMap.DeselectAnnotation.Request)
    func showDetail(request: ManageRouteMap.ShowDetail.Request)
    func editRoutePoint(request: ManageRouteMap.EditRoutePoint.Request)
    func deleteRoutePoint(request: ManageRouteMap.DeleteAnnotation.Request)
    func createRouteFragment(request: ManageRouteMap.CreateRouteFragment.Request)
    func deleteRouteFragment(request: ManageRouteMap.DeleteRouteFragment.Request)
    func mapRoute(request: ManageRouteMap.MapRoute.Request)
}

protocol ManageRouteMapDataStore {
    var tappedCoordinate: CLLocationCoordinate2D? { get set }
    var idOfSelectedAnnotation: String? { get set }
    var selectedRoutePoint: RoutePoint? { get set }
    var routePointToEdit: RoutePoint? { get set }
}

class ManageRouteMapInteractor: ManageRouteMapBusinessLogic, ManageRouteMapDataStore {
    var presenter: ManageRouteMapPresentationLogic?
    var worker: ManageRouteMapWorker?

    var idOfSelectedAnnotation: String?
    
    // IF YOU ARE GOING TO DELETE THIS REMEMBER THERE ARE A LOT OF DEPENDENCIES.
    var selectedRoutePoint: RoutePoint? {
        get {
            
            // TODO: Unreliable implementation.
            if let id = idOfSelectedAnnotation {
                return worker?.fetchRoutePoint(with: id)
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
    }
    
    // MARK: - Create route point
    
    var tappedCoordinate: CLLocationCoordinate2D?
    
    func createRoutePoint(request: ManageRouteMap.CreateRoutePoint.Request) {        
        tappedCoordinate = CLLocationCoordinate2D(latitude: request.latitude, longitude: request.longitude)
        let response = ManageRouteMap.CreateRoutePoint.Response()
        presenter?.presentAnnotationCreation(response: response)
    }
    
    // MARK: Fetch new annotations info
    var annotationsInfo: [AnnotationInfo]
    
    func fetchNewAnnotationsInfo(request: ManageRouteMap.FetchNewAnnotationsInfo.Request) {
        
        if let fetchedInfo = worker?.fetchNewAnnotationsInfo(comparingWith: idOfAlreadySettedRoutePoints) {
            let (addedAnnotationsInfo, idsOfRemovedRP) = fetchedInfo
            
            annotationsInfo.append(contentsOf: addedAnnotationsInfo)
            
            for id in idsOfRemovedRP {
                let indexToDelete = annotationsInfo.firstIndex(where: { return $0.id == id })
                annotationsInfo.remove(at: indexToDelete!)
            }
            
            let response = ManageRouteMap.FetchNewAnnotationsInfo.Response(newAnnotationsInfo: addedAnnotationsInfo,
                                                                           idsOfRemovedRoutePoints: idsOfRemovedRP)
            presenter?.presentFetchDifference(response: response)
        }
    }
    
    private var idOfAlreadySettedRoutePoints: [String] {
        let idList: [String]
        
        if annotationsInfo.count > 0 {
            idList = annotationsInfo.map({
                return $0.id
            })
            
            return idList
        } else {
            idList = []
            
            return idList
        }
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
    
    // MARK: Deselect Annotation
    
    func deselectAnnotation(request: ManageRouteMap.DeselectAnnotation.Request) {
        selectedRoutePoint = nil
        let response = ManageRouteMap.DeselectAnnotation.Response()
        presenter?.presentDeselectAnnotation(response: response)
    }
    
    // MARK: Show Detail
    
    func showDetail(request: ManageRouteMap.ShowDetail.Request) {
        let response = ManageRouteMap.ShowDetail.Response()
        presenter?.presentShowDetail(response: response)
    }
    
    // MARK: Edit Route Point
    
    var routePointToEdit: RoutePoint?
    
    func editRoutePoint(request: ManageRouteMap.EditRoutePoint.Request) {
        idOfSelectedAnnotation = request.identifier
        let response = ManageRouteMap.EditRoutePoint.Response()
        presenter?.presentEditRoutePoint(response: response)
    }
    
    // MARK: Delete Annotation
    
//    var routePointToDelete: RoutePoint?
    
    func deleteRoutePoint(request: ManageRouteMap.DeleteAnnotation.Request) {
        let response = ManageRouteMap.DeleteAnnotation.Response(identifier: request.identifier)
        presenter?.presentDeleteRoutePoint(response: response)
    }
    
    // MARK: Create Route Fragment
    
    func createRouteFragment(request: ManageRouteMap.CreateRouteFragment.Request) {
        
    }
    
    // MARK: Delete Route Fragment
    
    func deleteRouteFragment(request: ManageRouteMap.DeleteRouteFragment.Request) {
        
    }
    
    // MARK: Map Route
    
    func mapRoute(request: ManageRouteMap.MapRoute.Request) {
        
        let response = ManageRouteMap.MapRoute.Response()
        presenter?.presentMapRoute(response: response)
        // TODO: Check whether this is deletion or creation.
    }
}
