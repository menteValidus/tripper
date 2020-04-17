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
    func setDate(request: CreateRoutePoint.SetDate.Request)
    func toggleDatePicker(request: CreateRoutePoint.ToggleDatePicker.Request)
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
    
    var arrivalDate: Date!
    var departureDate: Date!
    
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
        
        arrivalDate = pointToSave?.arrivalDate
        departureDate = pointToSave?.departureDate
        
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
            pointToSave?.arrivalDate = arrivalDate
            pointToSave?.departureDate = departureDate
            
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
    
    // MARK: Set Date
    
    private var dateEditingState: CreateRoutePoint.AnnotationEditState = .normal
    
    func setDate(request: CreateRoutePoint.SetDate.Request) {
        let response = CreateRoutePoint.SetDate.Response(newDate: request.newDate, state: dateEditingState)
        presenter?.presentSetDate(response: response)
    }
    
    // MARK: Toggle Date Picker
    
    func toggleDatePicker(request: CreateRoutePoint.ToggleDatePicker.Request) {
//        let response: CreateRoutePoint.ToggleDatePicker.Response
        
        switch (request.section, request.row) {
        case (2, 0):
            let oldState = dateEditingState
            let newState: CreateRoutePoint.AnnotationEditState
            
            if oldState == .arrivalDateEditing {
                newState = .normal
            } else {
                newState = .arrivalDateEditing
            }
//                = CreateRoutePoint.AnnotationEditState.arrivalDateEditing
            dateEditingState = newState
            
            
            
            let response = CreateRoutePoint.ToggleDatePicker.Response(oldState: oldState, newState: newState)
            presenter?.presentToggleDatePicker(response: response)
            
//            switch dateEditingState {
//            case .normal:
//                dateEditingState = response.newState
////                showDatePicker(in: state)
//
//            case .arrivalDateEditing:
//                break
////                hideDatePicker(in: state)
//
//            case .departureDateEditing:
//                response = CreateRoutePoint.ToggleDatePicker.Response(oldState: dateEditingState, newState: .arrivalDateEditing)
//                hideDatePicker(in: state)
//                state = .arrivalDateEditing
//                showDatePicker(in: state)
//
//            }
            
        case (3, 0):
            let oldState = dateEditingState
            let newState: CreateRoutePoint.AnnotationEditState
            
            if oldState == .departureDateEditing {
                newState = .normal
            } else {
                newState = .departureDateEditing
            }
            
            dateEditingState = newState
            
            let response = CreateRoutePoint.ToggleDatePicker.Response(oldState: oldState, newState: newState)
            presenter?.presentToggleDatePicker(response: response)
            
        default:
            return
        }
        
        
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
