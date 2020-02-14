//
//  RouteDataModel.swift
//  Tripper
//
//  Created by Denis Cherniy on 03.02.2020.
//  Copyright © 2020 Denis Cherniy. All rights reserved.
//

import Foundation

class RouteDataModel {
    private(set) var points: [RoutePoint]
    
    private(set) var length = 0.0
    
    private let plistDAO = PropertyListDAO()
    private let dbGateway = CoreDataDAO()
    
    var subroutes: [Subroute] {
        var subroutes = [Subroute]()
        for index in 0..<points.count {
            let point = points[index]
            
            subroutes.append(Staying(title: point.title ?? "Staying #\(index)", minutes: point.residenceTimeInMinutes!))
            subroutes.append(InRoad(minutes: point.timeToGetToNextPointInMinutes!))
        }
        return subroutes
    }
    
    // Subroute means any division of main route. i.e. Stop in city for 2 days, road between points for 3 hours, etc.
    var countSubroutes: Int {
        if points.count > 0 {
            // This formula calculate overall number of route points and roads.
            return points.count * 2 - 1
        } else {
            return 0
        }
    }
    
    init() {
        points = dbGateway.fetchAll()
    }
    
    // MARK: - Helper Methods
    
    func clear() {
        points.removeAll()
    }
    
    func add(point: RoutePoint) {
        points.append(point)
        dbGateway.insert(point)
    }
    
    func update(routePoint: RoutePoint) {
        for index in 0..<points.count {
            if points[index].id == routePoint.id {
                points[index] = routePoint
                break
            }
        }
        
        dbGateway.update(routePoint)
    }
    
    func delete(routePoint: RoutePoint) {
        for (index, point) in points.enumerated() {
            if point.id == routePoint.id {
                points.remove(at: index)
                break
            }
        }
        
        dbGateway.delete(routePoint)
    }
    
    func getSubroute(at index: Int) -> Subroute {
        // We divide index by 2 to conform index of route point in points array.
        let i = index / 2
        let point = points[i]
        
        if index % 2 == 0 {
            return Staying(title: point.title ?? "Staying #\(i)", minutes: point.residenceTimeInMinutes!)
        } else {
            return InRoad(minutes: point.timeToGetToNextPointInMinutes!)
        }
    }
    
    func findRoutePoint(with id: Int) -> RoutePoint? {
        guard points.isEmpty else {
            return points[0]
        }
        
        return nil
    }
    
}
