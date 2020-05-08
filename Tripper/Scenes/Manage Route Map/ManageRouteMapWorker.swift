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

/// Created and deleted Route Points.
typealias FetchedDifference = ([AnnotationInfo], [AnnotationInfo])

class ManageRouteMapWorker {
    private let routePointGateway: RoutePointDataStore
    private let routeFragmentGateway: RouteFragmentDatastore
    
    private var lastFetchedRoutePoints: [RoutePoint]
    
    init() {
        let coreDatastore = CoreDatastore()
        routePointGateway = coreDatastore
        routeFragmentGateway = coreDatastore
        
        lastFetchedRoutePoints = []
    }
    
}

extension ManageRouteMapWorker {
    // MARK: - Annotations Info fetching
    
    func fetchRoutePointsDifference() -> FetchedDifference {
        let fetchedRoutePoints = routePointGateway.fetchAll()
        let (newAnnotationsInfo, idsOfRemovedRP) = findDifference(within: fetchedRoutePoints, with: lastFetchedRoutePoints)
        
        lastFetchedRoutePoints = fetchedRoutePoints
        
        return (newAnnotationsInfo, idsOfRemovedRP)
    }
    
//    private func findDifference(within passedRoutePoints: [RoutePoint], with annotationsInfoToCompareWith: [AnnotationInfo]) -> FetchedDifference {
//        var newAnnotationsInfo = [ManageRouteMap.ConcreteAnnotationInfo]()
//        var deletedAnnotationsInfo = annotationsInfoToCompareWith
//        
//        passedRoutePoints.forEach() { routePoint in
//            // Check whether this element already displayed.
//            let isContained = deletedAnnotationsInfo.contains(where: {
//                return $0.id == routePoint.id
//            })
//            
//            let annotationInfo = convertRoutePointToAnnotationInfo(routePoint: routePoint)
//            
//            if !isContained {
//                newAnnotationsInfo.append(annotationInfo)
//            } else {
//                // Remove this id from check list.
//                let index = deletedAnnotationsInfo.firstIndex(where: {
//                    return $0.id == routePoint.id
//                })
//                deletedAnnotationsInfo.remove(at: index!)
//            }
//        }
//        
//        return (newAnnotationsInfo, deletedAnnotationsInfo)
//    }
    
    private func findDifference(within passedRoutePoints: [RoutePoint], with routePointsToCompareWith: [RoutePoint]) -> ([RoutePoint], [RoutePoint]) {
        var newRoutePoints = [RoutePoint]()
        var deletedRoutePoints = routePointsToCompareWith
        
        passedRoutePoints.forEach() { routePoint in
            // Check whether this element already displayed.
            let isContained = deletedRoutePoints.contains(where: {
                return $0.id == routePoint.id
            })
            
//            let annotationInfo = convertRoutePointToAnnotationInfo(routePoint: routePoint)
            
            if !isContained {
                newRoutePoints.append(routePoint)
            } else {
                // Remove this id from check list.
                let index = deletedRoutePoints.firstIndex(where: {
                    return $0.id == routePoint.id
                })
                deletedRoutePoints.remove(at: index!)
            }
        }
        
        return (newRoutePoints, deletedRoutePoints)
    }
    
    func deleteAllEntries() {
        routePointGateway.deleteAll()
    }
    
    // MARK: - Helper Methods
    
//    private func convertRoutePointToAnnotationInfo(routePoint: RoutePoint) -> ManageRouteMap.ConcreteAnnotationInfo {
//        let annotationInfo = ManageRouteMap.ConcreteAnnotationInfo(id: routePoint.id, orderNumber: routePoint.orderNumber,
//                                                                   latitude: routePoint.latitude, longitude: routePoint.longitude)
//        return annotationInfo
//    }
//    
    // TODO: Temporal.
    func fetchRoutePoint(with id: String) -> RoutePoint {
        return routePointGateway.fetch(with: id)!
    }
}

extension ManageRouteMapWorker {
    // MARK: - Route Fragment Data Store
    
    func fetchRouteFragments() -> [RouteFragment] {
        let fetchedRouteFragments = routeFragmentGateway.fetchAll()
        return fetchedRouteFragments
    }
    
    func insert(routeFragment: RouteFragment) {
        routeFragmentGateway.insert(routeFragment)
    }
}
