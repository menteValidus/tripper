//
//  DetailRoutePointInteractor.swift
//  Tripper
//
//  Created by Denis Cherniy on 09.04.2020.
//  Copyright (c) 2020 Denis Cherniy. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol DetailRoutePointBusinessLogic {
    func setupUI(request: DetailRoutePoint.SetupUI.Request)
    func dismiss(request: DetailRoutePoint.Dismiss.Request)
    func edit(request: DetailRoutePoint.Edit.Request)
    func delete(request: DetailRoutePoint.Delete.Request)
    func toggleView(request: DetailRoutePoint.ToggleView.Request)
    func launchNavigator(request: DetailRoutePoint.LaunchNavigator.Request)
}

protocol DetailRoutePointDataStore {
    var routePoint: RoutePoint? { get set }
}

class DetailRoutePointInteractor: DetailRoutePointBusinessLogic, DetailRoutePointDataStore {
    var presenter: DetailRoutePointPresentationLogic?
    var worker: DetailRoutePointWorker?
    var routePoint: RoutePoint?
    
    // MARK: - Setup UI
    
    func setupUI(request: DetailRoutePoint.SetupUI.Request) {
        if let routePoint = routePoint {
            let response = DetailRoutePoint.SetupUI.Response(
                title: routePoint.title, description: routePoint.subtitle,
                arrivalDate: routePoint.arrivalDate, departureDate: routePoint.departureDate)
            
            presenter?.presentSetupUI(response: response)
        }
    }
    
    // MARK: Dismiss
    
    func dismiss(request: DetailRoutePoint.Dismiss.Request) {
        let response = DetailRoutePoint.Dismiss.Response()
        presenter?.presentDismiss(response: response)
    }
    
    // MARK: Edit Route Point
    
    func edit(request: DetailRoutePoint.Edit.Request) {
        let response = DetailRoutePoint.Edit.Response()
        presenter?.presentEdit(response: response)
    }
    
    // MARK: Delete Route Point
    
    func delete(request: DetailRoutePoint.Delete.Request) {
        if let routePoint = routePoint {
            let response = DetailRoutePoint.Delete.Response()
            worker?.delete(routePoint: routePoint)
            presenter?.presentDelete(response: response)
        }
    }
    
    // MARK: Toggle View
    
    func toggleView(request: DetailRoutePoint.ToggleView.Request) {
        let positionFromTheTop = Float(request.positionFromTheTop)
        let maxDistanceToPan = Float(request.maxDistanceToPan)
        let response: DetailRoutePoint.ToggleView.Response
        
        if positionFromTheTop < maxDistanceToPan * 1 / 3 {
            response = DetailRoutePoint.ToggleView.Response(screenCoverage: .mostPart)
        } else if positionFromTheTop < maxDistanceToPan * 2 / 3 {
            response = DetailRoutePoint.ToggleView.Response(screenCoverage: .smallPart)
        } else {
            if positionFromTheTop < maxDistanceToPan * 0.95 {
                response = DetailRoutePoint.ToggleView.Response(screenCoverage: .smallPart)
            } else {
                response = DetailRoutePoint.ToggleView.Response(screenCoverage: .toDismiss)
            }
        }
        
        presenter?.presentToggleView(response: response)
    }
    
    // MARK: Launch Navigator
    
    func launchNavigator(request: DetailRoutePoint.LaunchNavigator.Request) {
        if let routePoint = routePoint {
            presenter?.presentLaunchedNavigator(response: .init(routePoint: routePoint))
        }
    }
}
