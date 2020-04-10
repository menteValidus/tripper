//
//  CreateRoutePointInteractor.swift
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

protocol CreateRoutePointBusinessLogic {
    func formRoutePoint(request: CreateRoutePoint.FormRoutePoint.Request)
    func saveRoutePoint(request: CreateRoutePoint.SaveRoutePoint.Request)
    func cancelCreation(request: CreateRoutePoint.CancelCreation.Request)
}

protocol CreateRoutePointDataStore {
    var pointToSave: RoutePoint? { get set }
    var coordinateToCreateRP: CLLocationCoordinate2D? { get set }
}

class CreateRoutePointInteractor: CreateRoutePointBusinessLogic, CreateRoutePointDataStore {
    var presenter: CreateRoutePointPresentationLogic?
    var worker: CreateRoutePointWorker?
    
    private let idGenerator: IDGenerator = NSUUIDGenerator.instance
    
    // MARK: - Form Route Point
    
    func formRoutePoint(request: CreateRoutePoint.FormRoutePoint.Request) {
        let navigationTitle: String
        if pointToSave == nil {
            navigationTitle = "Create"
            if let coordinate = coordinateToCreateRP {
                pointToSave = createNewRoutePoint(at: coordinate)
            } else {
                fatalError("*** There is no way we can be here!")
            }
        } else {
            navigationTitle = "Edit"
        }
        
        let response = CreateRoutePoint.FormRoutePoint.Response(navigationTitle: navigationTitle, routePoint: pointToSave!)
        presenter?.presentFormRoutePoint(response: response)
    }
    
    // MARK: Save Route Point
    
    var pointToSave: RoutePoint?
    var coordinateToCreateRP: CLLocationCoordinate2D?

    func saveRoutePoint(request: CreateRoutePoint.SaveRoutePoint.Request) {
        if pointToSave != nil {
            pointToSave?.title = request.title
            pointToSave?.subtitle = request.description
            pointToSave?.arrivalDate = request.arrivalDate
            pointToSave?.departureDate = request.departureDate
            pointToSave?.timeToNextPointInSeconds = 0
            pointToSave?.distanceToNextPointInMeters = 0
            
            worker?.save(routePoint: pointToSave!)
            
            let response = CreateRoutePoint.SaveRoutePoint.Response()
            presenter?.presentSaveRoutePoint(response: response)
        } else {
            fatalError("*** There's no way we can be here!")
        }
    }
    
    // MARK: Cancel Creation
    
    func cancelCreation(request: CreateRoutePoint.CancelCreation.Request) {
        let response = CreateRoutePoint.CancelCreation.Response()
        presenter?.presentCancelCreation(response: response)
    }
    
    // MARK: - Helper Methods
    
    private func createNewRoutePoint(at coordinate: CLLocationCoordinate2D) -> RoutePoint {
        let routePoint = RoutePoint(
            id: idGenerator.generate(), orderNumber: 0,
            title: "", subtitle: "",
            latitude: coordinate.latitude, longitude: coordinate.longitude)
        return routePoint
    }
}
