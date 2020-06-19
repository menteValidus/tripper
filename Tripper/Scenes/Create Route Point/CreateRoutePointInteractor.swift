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
    func fetchDateLimits(request: CreateRoutePoint.FetchDateLimits.Request)
    func saveRoutePoint(request: CreateRoutePoint.SaveRoutePoint.Request)
    func cancelCreation(request: CreateRoutePoint.CancelCreation.Request)
    func setDate(request: CreateRoutePoint.SetDate.Request)
    func toggleDateEditState(request: CreateRoutePoint.ToggleDateEditState.Request)
    func showDatePicker(request: CreateRoutePoint.ShowDatePicker.Request)
    func hideDatePicker(request: CreateRoutePoint.HideDatePicker.Request)
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
    
    // MARK: Fetch Date Limits
    
    private var leftDateLimit: Date?
    private var rightDateLimit: Date?
    
    func fetchDateLimits(request: CreateRoutePoint.FetchDateLimits.Request) {
        leftDateLimit = worker?.getLeftDateLimit(by: pointToSave!.orderNumber)
        rightDateLimit = worker?.getRightDateLimit(by: pointToSave!.orderNumber)
        
        let response = CreateRoutePoint.FetchDateLimits.Response()
        presenter?.presentFetchDateLimits(response: response)
    }
    
    // MARK: Save Route Point
    
    var pointToSave: RoutePoint?
    var dataToCreateRoutePoint: SimpleRoutePointInfo?
    
    func saveRoutePoint(request: CreateRoutePoint.SaveRoutePoint.Request) {
        if pointToSave != nil {
            pointToSave?.title = request.title
            pointToSave?.subtitle = request.description
            
            if let errorMessage = compareDateWithLeftLimit(date: arrivalDate) {
                let response = CreateRoutePoint.SaveRoutePoint.Response(errorMessage: errorMessage)
                presenter?.presentSaveRoutePoint(response: response)
                return
            }
            pointToSave?.arrivalDate = arrivalDate
            
            if let errorMessage = compareDateWithRightLimit(date: departureDate) {
                let response = CreateRoutePoint.SaveRoutePoint.Response(errorMessage: errorMessage)
                presenter?.presentSaveRoutePoint(response: response)
                return
            }
            pointToSave?.departureDate = departureDate
            
            worker?.save(routePoint: pointToSave!)
            
            let response = CreateRoutePoint.SaveRoutePoint.Response(errorMessage: nil)
            presenter?.presentSaveRoutePoint(response: response)
        } else {
            fatalError("*** There's no way we can be here!")
        }
    }
    
    private func compareDateWithLeftLimit(date: Date) -> String? {
        if date.compareWithoutSeconds(with: departureDate) == ComparisonResult.orderedDescending { // >
            let errorMessage = "New Arrival Date lies beyond Departure Date!"
            return errorMessage
        }
        
        if let leftLimit = leftDateLimit {
            if date.compareWithoutSeconds(with: leftLimit) == ComparisonResult.orderedAscending { // <
                let errorMessage = "New Arrival Date lies beyond Departure Date of previous Route Point!"
                return errorMessage
            }
        }
        
        return nil
    }
    
    private func compareDateWithRightLimit(date: Date) -> String? {
        if date.compareWithoutSeconds(with: arrivalDate) == ComparisonResult.orderedAscending { // <
            // This code probably will be never executed because this situation is handled in compareDateWithLeftLimit.
            // But this method sometime can be used separately from compareDateWithLeftLimit that's why this check is lefted here.
            let errorMessage = "New Departure Date lies beyond Arrival Date!"
            return errorMessage
        }
        
        if let rightLimit = rightDateLimit {
            if date.compareWithoutSeconds(with: rightLimit) == ComparisonResult.orderedDescending { // >
                let errorMessage = "New Departure Date lies beyond Arrival Date of next Route Point!"
                return errorMessage
            }
        }
        
        return nil
    }
    
    // MARK: Cancel Creation
    
    func cancelCreation(request: CreateRoutePoint.CancelCreation.Request) {
        let response = CreateRoutePoint.CancelCreation.Response()
        presenter?.presentCancelCreation(response: response)
    }
    
    // MARK: Set Date
    
    private var dateEditingState: CreateRoutePoint.AnnotationEditState = .normal
    
    func setDate(request: CreateRoutePoint.SetDate.Request) {
        switch dateEditingState {
        case .arrivalDateEditing:
            arrivalDate = request.newDate
            
        case .departureDateEditing:
            departureDate = request.newDate
            
        default:
            return
        }
        
        let response = CreateRoutePoint.SetDate.Response(newDate: request.newDate, state: dateEditingState)
        presenter?.presentSetDate(response: response)
    }
    
    // MARK: Toggle Date Picker
    
    func toggleDateEditState(request: CreateRoutePoint.ToggleDateEditState.Request) {
        
        switch (request.section, request.row) {
        case (2, 0):
            let oldState = dateEditingState
            let newState: CreateRoutePoint.AnnotationEditState
            
            if oldState == .arrivalDateEditing {
                newState = .normal
            } else {
                newState = .arrivalDateEditing
            }
            
            dateEditingState = newState
            
            let response = CreateRoutePoint.ToggleDateEditState.Response(oldState: oldState, newState: newState)
            presenter?.presentToggleDateEditState(response: response)
            
        case (3, 0):
            let oldState = dateEditingState
            let newState: CreateRoutePoint.AnnotationEditState
            
            if oldState == .departureDateEditing {
                newState = .normal
            } else {
                newState = .departureDateEditing
            }
            
            dateEditingState = newState
            
            let response = CreateRoutePoint.ToggleDateEditState.Response(oldState: oldState, newState: newState)
            presenter?.presentToggleDateEditState(response: response)
            
        default:
            return
        }

    }
    
    // MARK: Show Date Picker
    
    func showDatePicker(request: CreateRoutePoint.ShowDatePicker.Request) {
        let state = request.state
        let date: Date
        
        if state == .arrivalDateEditing {
            date = arrivalDate
        } else {
            date = departureDate
        }
        
        let response = CreateRoutePoint.ShowDatePicker.Response(state: state, date: date)
        presenter?.presentShowDatePicker(response: response)
    }
    
    // MARK: Hide Date Picker
    
    func hideDatePicker(request: CreateRoutePoint.HideDatePicker.Request) {
        let response = CreateRoutePoint.HideDatePicker.Response(state: request.state)
        presenter?.presentHideDatePicker(response: response)
    }
    
    // MARK: - Helper Methods
    
    private func createNewRoutePoint(with data: SimpleRoutePointInfo) -> RoutePoint {
        let id = idGenerator.generate()
        let orderNumber = worker!.getNewOrderNumber()
        let title = data.title == nil ? "Route Point #\(orderNumber)" : data.title!
        let subtitle = ""
        let latitude = data.tappedCoordinate.latitude
        let longitude = data.tappedCoordinate.longitude
        let arrivalDate = worker!.getLeftDateLimit(by: orderNumber)?.addingTimeInterval(TimeInterval(data.timeToNextPointInSeconds)) ?? Date()
        let departureDate = arrivalDate
        let routePoint = RoutePoint(id: id, orderNumber: orderNumber,
                                    title: title, subtitle: subtitle,
                                    latitude: latitude, longitude: longitude,
                                    arrivalDate: arrivalDate, departureDate: departureDate)
        return routePoint
    }
}
