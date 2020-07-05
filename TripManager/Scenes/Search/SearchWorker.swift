//
//  SearchWorker.swift
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

class SearchWorker {
    let searchApiGateway: SearchApiGateway
    
    init(searchApiGateway: SearchApiGateway) {
        self.searchApiGateway = searchApiGateway
    }
    
    func search(with query: String, completionHandler: @escaping ([PointInfo]) -> Void) {
        searchApiGateway.performSearch(with: query) { pointsInfo in
            completionHandler(pointsInfo)
        }
    }
}