//
//  ManageRouteMapRouter.swift
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

@objc protocol ManageRouteMapRoutingLogic {
    func routeToCreateRoutePoint(segue: UIStoryboardSegue?)
    func routeToDetailRoutePoint(segue: UIStoryboardSegue?)
}

protocol ManageRouteMapDataPassing {
    var dataStore: ManageRouteMapDataStore? { get }
}

class ManageRouteMapRouter: NSObject, ManageRouteMapRoutingLogic, ManageRouteMapDataPassing {
    weak var viewController: ManageRouteMapViewController?
    var dataStore: ManageRouteMapDataStore?
    
    // MARK: Routing
    
    func routeToCreateRoutePoint(segue: UIStoryboardSegue?) {
        if let segue = segue {
            let destinationVC = segue.destination as! CreateRoutePointViewController
            var destinationDS = destinationVC.router!.dataStore!
            passDataToCreateRoutePoint(source: dataStore!, destination: &destinationDS)
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let destinationVC = storyboard.instantiateViewController(withIdentifier: "CreateRoutePointViewController") as! CreateRoutePointViewController
                var destinationDS = destinationVC.router!.dataStore!
                passDataToCreateRoutePoint(source: dataStore!, destination: &destinationDS)
                navigateToCreateRoutePoint(source: viewController!, destination: destinationVC)
        }
    }
    
    func routeToDetailRoutePoint(segue: UIStoryboardSegue?) {
        if let segue = segue {
            let destinationVC = segue.destination as! DetailRoutePointViewController
            var destinationDS = destinationVC.router!.dataStore!
            passDataToDetailRoutePoint(source: dataStore!, destination: &destinationDS)
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let destinationVC = storyboard.instantiateViewController(withIdentifier: "DetailRoutePointViewController") as! DetailRoutePointViewController
                var destinationDS = destinationVC.router!.dataStore!
                passDataToDetailRoutePoint(source: dataStore!, destination: &destinationDS)
                navigateToDetailRoutePoint(source: viewController!, destination: destinationVC)
        }
    }
    
    // MARK: Navigation
    
    func navigateToCreateRoutePoint(source: ManageRouteMapViewController, destination: CreateRoutePointViewController)
    {
      source.show(destination, sender: nil)
    }
    
    func navigateToDetailRoutePoint(source: ManageRouteMapViewController, destination: DetailRoutePointViewController)
    {
      source.show(destination, sender: nil)
    }
    
    // MARK: Passing data
    
    func passDataToCreateRoutePoint(source: ManageRouteMapDataStore, destination: inout CreateRoutePointDataStore)
    {
        destination.coordinateToCreateRP = source.tappedCoordinate
    }
    
    func passDataToDetailRoutePoint(source: ManageRouteMapDataStore, destination: inout DetailRoutePointDataStore)
    {
        destination.routePoint = source.selectedRoutePoint
    }
}
