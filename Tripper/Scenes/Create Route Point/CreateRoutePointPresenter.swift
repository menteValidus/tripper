//
//  CreateRoutePointPresenter.swift
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

protocol CreateRoutePointPresentationLogic {
    func presentFormRoutePoint(response: CreateRoutePoint.FormRoutePoint.Response)
    func presentSaveRoutePoint(response: CreateRoutePoint.SaveRoutePoint.Response)
    func presentCancelCreation(response: CreateRoutePoint.CancelCreation.Response)
}

class CreateRoutePointPresenter: CreateRoutePointPresentationLogic {
    weak var viewController: CreateRoutePointDisplayLogic?
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .medium
        return dateFormatter
    }()
    
    // MARK: - Form Route Point
    
    func presentFormRoutePoint(response: CreateRoutePoint.FormRoutePoint.Response) {
        let navigationTitle = response.navigationTitle
        
        let title = response.routePoint.title
        let subtitle = response.routePoint.subtitle
        
        let arrivalDate = response.routePoint.arrivalDate ?? Date()
        let arrivalDateString = dateFormatter.string(from: arrivalDate)
        
        let departureDate = response.routePoint.departureDate ?? Date()
        let departureDateString = dateFormatter.string(from: departureDate)
        
        let annotationForm = CreateRoutePoint.DisplayableAnnotationInfo(
            title: title, subtitle: subtitle, arrivalDate: arrivalDateString, departureDate: departureDateString)
        
        let viewModel = CreateRoutePoint.FormRoutePoint.ViewModel(navigationTitle: navigationTitle, annotationForm: annotationForm)
        viewController?.displayRoutePointForm(viewModel: viewModel)
    }
    
    // MARK: Save Route Point
    
    func presentSaveRoutePoint(response: CreateRoutePoint.SaveRoutePoint.Response) {
        let viewModel = CreateRoutePoint.SaveRoutePoint.ViewModel()
        viewController?.displaySaveRoutePoint(viewModel: viewModel)
    }
    
    // MARK: Cancel Creation
    
    func presentCancelCreation(response: CreateRoutePoint.CancelCreation.Response) {
        let viewModel = CreateRoutePoint.CancelCreation.ViewModel()
        viewController?.displayCancelCreation(viewModel: viewModel)
    }
}
