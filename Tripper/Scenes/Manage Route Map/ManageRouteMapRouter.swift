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
            let destinationVC: DetailRoutePointViewController
            
            if let viewController = dataStore?.popup as? DetailRoutePointViewController {
                destinationVC = viewController
            } else {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                destinationVC = storyboard.instantiateViewController(withIdentifier: "DetailRoutePointViewController") as! DetailRoutePointViewController
            }
            
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
        if let popup = source.router?.dataStore?.popup {
            popup.updateUI()
        } else {
            let height = source.view.frame.height
            let width  = source.view.frame.width
            let bottomOffset = UIApplication.shared.statusBarFrame.height + 15
            
            source.addChild(destination)
            source.view.addSubview(destination.view)
            destination.view.frame = CGRect(x: 0, y: height, width: width, height: height)
            destination.view.isUserInteractionEnabled = true
            destination.didMove(toParent: source)
            
            
            let yCoordinate = source.view.frame.height * 0.75
            UIView.animate(withDuration: 0.3) {
                destination.view.frame = CGRect(x: 0, y: yCoordinate, width: width, height: yCoordinate + bottomOffset)
            }
            
            // TODO: Not sure that it belongs here.
            dataStore?.popup = destination
        }
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
