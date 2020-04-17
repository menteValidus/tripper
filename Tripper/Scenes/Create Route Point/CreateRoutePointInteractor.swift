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
    var dataToCreateRoutePoint: SimpleRoutePointInfo? { get set }
}

class CreateRoutePointInteractor: CreateRoutePointBusinessLogic, CreateRoutePointDataStore {
    var presenter: CreateRoutePointPresentationLogic?
    var worker: CreateRoutePointWorker?
    
    private let idGenerator: IDGenerator = NSUUIDGenerator()
    
    // MARK: - Form Route Point
    
    func formRoutePoint(request: CreateRoutePoint.FormRoutePoint.Request) {
        let navigationTitle: String
        if pointToSave == nil {
            navigationTitle = "Create"
            if let data = dataToCreateRoutePoint {
                pointToSave = createNewRoutePoint(with: data)
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
    var dataToCreateRoutePoint: SimpleRoutePointInfo?

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
    
    private func createNewRoutePoint(with data: SimpleRoutePointInfo) -> RoutePoint {
        let id = idGenerator.generate()
        let orderNumber = worker!.getNewOrderNumber()
        let title = "Route Point #\(orderNumber)"
        let subtitle = ""
        let latitude = data.tappedCoordinate.latitude
        let longitude = data.tappedCoordinate.longitude
        let arrivalDate = worker!.getLeftLimit(by: orderNumber).addingTimeInterval(TimeInterval(data.timeToNextPointInSeconds))
        let departureDate = Date()
        let distance = data.distanceToNextPointInMeters
        let routePoint = RoutePoint(id: id, orderNumber: orderNumber,
                                    title: title, subtitle: subtitle,
                                    latitude: latitude, longitude: longitude,
                                    arrivalDate: arrivalDate, departureDate: departureDate,
                                    distanceToNextPointInMeters: distance)
        return routePoint
    }
}
