//
//  ManageRouteMapWorker.swift
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

class ManageRouteMapWorker {
    private let routePointGateway: RoutePointDataStore = RoutePointCoreDataStore()
    
    private let routePoints: [RoutePoint] = []
    
    func fetchNewAnnotationsInfo() -> [ManageRouteMap.ConcreteAnnotationInfo] {
        let fetchedRoutePoints = routePointGateway.fetchAll()
        var newAnnotationsInfo = [ManageRouteMap.ConcreteAnnotationInfo]()
        
        fetchedRoutePoints.forEach() { routePoint in
            let isContained = routePoints.contains(where: {
                return $0.id == routePoint.id
            })
            
            if !isContained {
                let annotationInfo = convertRoutePointToAnnotationInfo(routePoint: routePoint)
                newAnnotationsInfo.append(annotationInfo)
            }
        }
        
        return newAnnotationsInfo
    }
    
    private func convertRoutePointToAnnotationInfo(routePoint: RoutePoint) -> ManageRouteMap.ConcreteAnnotationInfo {
        let annotationInfo = ManageRouteMap.ConcreteAnnotationInfo(id: routePoint.id, latitude: routePoint.latitude, longitude: routePoint.longitude)
        return annotationInfo
    }
    
    // TODO: Temporal.
    func fetchRoutePoint(with id: String) -> RoutePoint {
        return routePointGateway.fetch(with: id)!
    }
}
