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
    func routeToEditRoutePoint(segue: UIStoryboardSegue?)
    func routeToListRoute(segue: UIStoryboardSegue?)
    func routeToFastNavigation(segue: UIStoryboardSegue?)
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
            
            if let viewController = viewController?.popup as? DetailRoutePointViewController {
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
    
    func routeToEditRoutePoint(segue: UIStoryboardSegue?) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let destinationVC = storyboard.instantiateViewController(withIdentifier: "CreateRoutePointViewController") as! CreateRoutePointViewController
        var destinationDS = destinationVC.router!.dataStore!
        passDataToEditRoutePoint(source: dataStore!, destination: &destinationDS)
        navigateToEditRoutePoint(source: viewController!, destination: destinationVC)
    }
    
    func routeToListRoute(segue: UIStoryboardSegue?) {
        if let segue = segue {
            let destinationVC = segue.destination as! ListRouteViewController
            var destinationDS = destinationVC.router!.dataStore!
            passDataToListRoute(source: dataStore!, destination: &destinationDS)
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let destinationVC = storyboard.instantiateViewController(withIdentifier: "ListRouteViewController") as! ListRouteViewController
            var destinationDS = destinationVC.router!.dataStore!
            passDataToListRoute(source: dataStore!, destination: &destinationDS)
            navigateToListRoute(source: viewController!, destination: destinationVC)
        }
    }
    
    func routeToFastNavigation(segue: UIStoryboardSegue?) {
        let destinationVC: FastNavigationViewController
        
//        if let viewController = viewController?.popup as? DetailRoutePointViewController {
//            destinationVC = viewController
//        } else {
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            destinationVC = FastNavigationViewController()
//        }
        
        var destinationDS = destinationVC.router!.dataStore!
        passDataToFastNavigation(source: dataStore!, destination: &destinationDS)
        navigateToFastNavigation(source: viewController!, destination: destinationVC)
    }
    
    // MARK: Navigation
    
    func navigateToCreateRoutePoint(source: ManageRouteMapViewController, destination: CreateRoutePointViewController)
    {
        source.show(destination, sender: nil)
    }
    
    func navigateToDetailRoutePoint(source: ManageRouteMapViewController, destination: DetailRoutePointViewController)
    {
        if let popup = source.popup {
            popup.updateUI()
        } else {
            let height = source.view.frame.height
            let width  = source.view.frame.width
            let topOffset = source.navigationController!.navigationBar.frame.height
            
            source.addChild(destination)
            source.view.addSubview(destination.view)
            destination.view.frame = CGRect(x: 0, y: height, width: width, height: height - topOffset)
            destination.view.isUserInteractionEnabled = true
            destination.didMove(toParent: source)
            
            let percent = CGFloat(1 - PopupCoverage.smallPart.rawValue)
            let yCoordinate = source.view.frame.height * percent
            UIView.animate(withDuration: 0.3) {
                destination.view.frame = CGRect(x: 0, y: yCoordinate, width: width, height: height - topOffset)
            }
            
            source.popup = destination
        }
    }
    
    func navigateToEditRoutePoint(source: ManageRouteMapViewController, destination: CreateRoutePointViewController) {
        source.show(destination, sender: nil)
    }
    
    func navigateToListRoute(source: ManageRouteMapViewController, destination: ListRouteViewController) {
        source.show(destination, sender: nil)
    }
    
    func navigateToFastNavigation(source: ManageRouteMapViewController, destination: FastNavigationViewController) {
        let topOffset = source.view.safeAreaInsets.top
        let bottomOffset = source.view.safeAreaInsets.bottom
        
        source.addChild(destination)
        source.view.addSubview(destination.view)
        
        let height = source.view.frame.height - (topOffset + bottomOffset)
        let width  = source.view.frame.width
        destination.view.frame = CGRect(x: width, y: topOffset, width: width / 3, height: height)
        destination.view.isUserInteractionEnabled = true
        destination.didMove(toParent: source)
        
        let xCoordinate = width * 2/3
        UIView.animate(withDuration: 0.3) {
            destination.view.frame = CGRect(x: xCoordinate, y: topOffset, width: width / 3, height: height)
        }
    }
    
    // MARK: Passing data
    
    func passDataToCreateRoutePoint(source: ManageRouteMapDataStore, destination: inout CreateRoutePointDataStore)
    {
        destination.dataToCreateRoutePoint = source.dataToCreateRoutePoint
    }
    
    func passDataToDetailRoutePoint(source: ManageRouteMapDataStore, destination: inout DetailRoutePointDataStore)
    {
        destination.routePoint = source.selectedRoutePoint
    }
    
    func passDataToEditRoutePoint(source: ManageRouteMapDataStore, destination: inout CreateRoutePointDataStore) {
        destination.pointToSave = source.routePointToEdit
    }
    
    func passDataToListRoute(source: ManageRouteMapDataStore, destination: inout ListRouteDataStore) {
    }
    
    func passDataToFastNavigation(source: ManageRouteMapDataStore, destination: inout FastNavigationDataStore) {
    }
}
