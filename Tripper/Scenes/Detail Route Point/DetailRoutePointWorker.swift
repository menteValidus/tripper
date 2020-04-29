//
//  DetailRoutePointWorker.swift
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

class DetailRoutePointWorker {
    private let routePointGateway: RoutePointDataStore = RoutePointCoreDataStore()
    
    func delete(routePoint: RoutePoint) {
        routePointGateway.delete(routePoint)
    }
}
