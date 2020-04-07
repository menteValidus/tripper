//
//  ManageRouteMapInteractor.swift
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

protocol ManageRouteMapBusinessLogic {
//    func getAnnotationsInfo(request: ManageRouteMap.Something.Request)
    func createAnnotation(request: ManageRouteMap.SetAnnotation.Request)
}

protocol ManageRouteMapDataStore {
    //var name: String { get set }
}

class ManageRouteMapInteractor: ManageRouteMapBusinessLogic, ManageRouteMapDataStore {
    var presenter: ManageRouteMapPresentationLogic?
    var worker: ManageRouteMapWorker?
    var annotationsInfo: [ManageRouteMap.AnnotationInfo]
    var idGenerator: IDGenerator
    //var name: String = ""
    
    init() {
        annotationsInfo = []
        idGenerator = NSUUIDGenerator.instance
    }
    
    // MARK: Use cases
    
    func createAnnotation(request: ManageRouteMap.SetAnnotation.Request) {
        let id = idGenerator.generate()
        let response = ManageRouteMap.SetAnnotation.Response(id: id, latitude: request.latitude, longitude: request.longitude)
        presenter?.presentAnnotation(response: response)
    }
}
