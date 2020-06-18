//
//  SearchInteractor.swift
//  Tripper
//
//  Created by Denis Cherniy on 16.06.2020.
//  Copyright (c) 2020 Denis Cherniy. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol SearchBusinessLogic {
    func performSearch(request: Search.PerformSearch.Request)
    func selectEntry(request: Search.SelectEntry.Request)
}

protocol SearchDataStore {
}

class SearchInteractor: SearchBusinessLogic, SearchDataStore {
    var presenter: SearchPresentationLogic?
    var worker: SearchWorker?
    
    // MARK: - Perform Search
    
    var pointsInfo: [PointInfo] = []
    
    func performSearch(request: Search.PerformSearch.Request) {
        worker!.search(with: request.query, completionHandler: { pointsInfo in
            self.pointsInfo = pointsInfo
            self.presenter?.presentPerformedSearch(response: .init(pointsInfo: pointsInfo))
        })
    }
    
    // MARK: SelectEntry
    
    func selectEntry(request: Search.SelectEntry.Request) {
        let entry = pointsInfo[request.entryNumber]
        presenter?.presentEntrySelection(response: .init(center: entry.center,
                                                         southWestCoordinate: entry.southWestCoordinate,
                                                         northSouthCoordinate: entry.northEastCoordinate))
    }
}