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
import CoreLocation
import Swinject

protocol ManageRouteMapBusinessLogic {
    func setupData(request: ManageRouteMap.SetupData.Request)
    func fetchDifference(request: ManageRouteMap.FetchDifference.Request)
    func updateRouteProgress(request: ManageRouteMap.UpdateRouteProgress.Request)
    func createRoutePoint(request: ManageRouteMap.CreateRoutePoint.Request)
    func setRoutePoint(request: ManageRouteMap.SetRoutePoint.Request)
    func selectAnnotation(request: ManageRouteMap.SelectAnnotation.Request)
    func deselectAnnotation(request: ManageRouteMap.DeselectAnnotation.Request)
    func showDetail(request: ManageRouteMap.ShowDetail.Request)
    func editRoutePoint(request: ManageRouteMap.EditRoutePoint.Request)
    func deleteRoutePoint(request: ManageRouteMap.DeleteAnnotation.Request)
    func createRouteFragment(request: ManageRouteMap.CreateRouteFragment.Request)
    func addRouteFragment(request: ManageRouteMap.AddRouteFragment.Request)
    func deleteRouteFragment(request: ManageRouteMap.DeleteRouteFragment.Request)
    func mapRoute(request: ManageRouteMap.MapRoute.Request)
    func clearAll(request: ManageRouteMap.ClearAll.Request)
    func toggleUserInput(request: ManageRouteMap.ToggleUserInput.Request)
    func focus(request: ManageRouteMap.Focus.Request)
    func focusOnRoute(request: ManageRouteMap.FocusOnRoute.Request)
    func focusOnUser(request: ManageRouteMap.FocusOnUser.Request)
    func focusOnCoordinates(request: ManageRouteMap.FocusOnCoordinates.Request)
    func routeEstimation(request: ManageRouteMap.RouteEstimation.Request)
    func createTemporaryPoint(request: ManageRouteMap.CreateTemporaryPoint.Request)
    func removeTemporaryPoint(request: ManageRouteMap.RemoveTemporaryPoint.Request)
}

struct SimpleRoutePointInfo {
    var title: String? = nil
    let tappedCoordinate: CLLocationCoordinate2D
    let timeToNextPointInSeconds: Int
    let distanceToNextPointInMeters: Int
}

protocol ManageRouteMapDataStore {
    var dataToCreateRoutePoint: SimpleRoutePointInfo? { get set }
    var idOfSelectedAnnotation: String? { get set }
    var selectedRoutePoint: RoutePoint? { get set }
    var routePointToEdit: RoutePoint? { get set }
}

class ManageRouteMapInteractor: ManageRouteMapBusinessLogic, ManageRouteMapDataStore {
    var presenter: ManageRouteMapPresentationLogic?
    var worker: ManageRouteMapWorker?
    var routeCreator: RouteCreator

    var idOfSelectedAnnotation: String?
    
    // IF YOU ARE GOING TO DELETE THIS REMEMBER THERE ARE A LOT OF DEPENDENCIES.
    var selectedRoutePoint: RoutePoint? {
        get {
            
            // TODO: Unreliable implementation.
            if let id = idOfSelectedAnnotation {
                return worker?.fetchRoutePoint(with: id)
            } else {
                return nil
            }
        }
        
        set {
            idOfSelectedAnnotation = newValue?.id
        }
    }
    
    init() {
        routeCreator = Container.shared.resolve(RouteCreator.self)!
        annotationsInfo = []
        routeFragments = []
    }
    
    // MARK: - Data Setup
    
    func setupData(request: ManageRouteMap.SetupData.Request) {
        let (fetchedAnnotationsInfo, _) = worker!.fetchRoutePointsDifference()
        self.annotationsInfo = fetchedAnnotationsInfo
        let routeFragments = worker!.fetchRouteFragments()
        self.routeFragments = routeFragments
        
        let response = ManageRouteMap.SetupData.Response(annotationsInfo: annotationsInfo, routeFragments: routeFragments)
        presenter?.presentDataSetup(response: response)
    }
    
    // MARK: Create route point
    
    var dataToCreateRoutePoint: SimpleRoutePointInfo?
    
    func createRoutePoint(request: ManageRouteMap.CreateRoutePoint.Request) {
        let sortedAnnotationsInfo = annotationsInfo.sorted(by: { lhs, rhs in
        return lhs.orderNumber < rhs.orderNumber
        })
        
        let tappedCoordinate = CLLocationCoordinate2D(latitude: request.latitude, longitude: request.longitude)
        if let lastAnnotation = sortedAnnotationsInfo.last {
            let lastAnnotationCoordinate = CLLocationCoordinate2D(latitude: lastAnnotation.latitude, longitude: lastAnnotation.longitude)
            
            routeCreator.calculateRoute(from: lastAnnotationCoordinate, to: tappedCoordinate, drawHandler: { routeInfo in
                if let routeInfo = routeInfo {
                    self.dataToCreateRoutePoint = SimpleRoutePointInfo(title: request.title, tappedCoordinate: tappedCoordinate, timeToNextPointInSeconds: routeInfo.timeInSeconds, distanceToNextPointInMeters: routeInfo.distanceInMeters)
                    
                    let response = ManageRouteMap.CreateRoutePoint.Response(isSucceed: true)
                    self.presenter?.presentCreateRoutePoint(response: response)
                } else {
                    let response = ManageRouteMap.CreateRoutePoint.Response(isSucceed: false)
                    self.presenter?.presentCreateRoutePoint(response: response)
                }
            })
        } else {
            dataToCreateRoutePoint = SimpleRoutePointInfo(title: request.title, tappedCoordinate: tappedCoordinate,
                                                          timeToNextPointInSeconds: 0, distanceToNextPointInMeters: 0)
            
            let response = ManageRouteMap.CreateRoutePoint.Response(isSucceed: true)
            presenter?.presentCreateRoutePoint(response: response)
        }
    }
    
    // MARK: - Fetch Difference
    
    var annotationsInfo: [AnnotationInfo]
    
    func fetchDifference(request: ManageRouteMap.FetchDifference.Request) {
        
        if let fetchedInfo = worker?.fetchRoutePointsDifference() {
            let (addedAnnotationsInfo, removedAnnotationsInfo) = fetchedInfo
            
            annotationsInfo.append(contentsOf: addedAnnotationsInfo)
            
            for annotationInfo in removedAnnotationsInfo {
                let indexToDelete = annotationsInfo.firstIndex(where: { return $0.id == annotationInfo.id })
                annotationsInfo.remove(at: indexToDelete!)
            }
            
            let response = ManageRouteMap.FetchDifference.Response(newAnnotationsInfo: addedAnnotationsInfo,
                                                                           removedAnnotationInfo: removedAnnotationsInfo)
            presenter?.presentFetchDifference(response: response)
        }
    }
    
    // MARK: Update Route Progress
    
    func updateRouteProgress(request: ManageRouteMap.UpdateRouteProgress.Request) {
        let routePoint = request.routePoint
        
        let routePointsProgressInfo = createRoutePointsProgressInfo(with: routePoint)
        worker?.updateProgress(with: routePointsProgressInfo)
        annotationsInfo = worker!.fetchRoutePoints()
        let routeFragmentsProgressInfo = createRouteFragmentsProgressInfo(from: routePointsProgressInfo)
        
        presenter?.presentUpdatedRouteProgress(response: .init(routePointProgressInfo: routePointsProgressInfo,
                                                               routeFragmentProgressInfo: routeFragmentsProgressInfo))
    }
    
    // MARK: Helper Methods
    
    private func createRoutePointsProgressInfo(with routePoint: RoutePoint) -> [ManageRouteMap.RoutePointProgressInfo] {
        var routePointsProgressInfo: [ManageRouteMap.RoutePointProgressInfo] = []
        
        if routePoint.isFinished {
            let previousRoutePointsProgressInfo = annotationsInfo.filter({
                $0.orderNumber <= routePoint.orderNumber
            }).map { ManageRouteMap.RoutePointProgressInfo(type: .routePoint, id: $0.id, orderNumber: $0.orderNumber, isFinished: true) }
            
            routePointsProgressInfo.append(contentsOf: previousRoutePointsProgressInfo)
        } else {
            var nextRoutePointsProgressInfo = annotationsInfo.filter({
                $0.orderNumber >= routePoint.orderNumber
            }).map { ManageRouteMap.RoutePointProgressInfo(type: .routePoint, id: $0.id, orderNumber: $0.orderNumber, isFinished: false) }
            
            let letfRoutePoint = annotationsInfo.filter({ $0.orderNumber < routePoint.orderNumber }).first
            
            if let oddRoutePoint = letfRoutePoint {
                let leftRoutePointProgressInfo = ManageRouteMap.RoutePointProgressInfo(type: .routePoint, id: oddRoutePoint.id,
                                                                             orderNumber: oddRoutePoint.orderNumber,
                                                                             isFinished: oddRoutePoint.isFinished)
                nextRoutePointsProgressInfo.append(leftRoutePointProgressInfo)
            }
            
            routePointsProgressInfo.append(contentsOf: nextRoutePointsProgressInfo)
        }
        
        return routePointsProgressInfo
    }
    
    private func createRouteFragmentsProgressInfo(from routePointsProgressInfo: [ManageRouteMap.RoutePointProgressInfo]) -> [ManageRouteMap.RouteFragmentProgressInfo] {
        let routePointsProgressInfo = routePointsProgressInfo.sorted(by: { lhs, rhs in
            lhs.orderNumber < rhs.orderNumber
        })
        
        if routePointsProgressInfo.count > 0 {
            var routeFragmentsProgressInfo: [ManageRouteMap.RouteFragmentProgressInfo] = []
            
            for index in 0..<(routePointsProgressInfo.count - 1) {
                let id = format(firstID: routePointsProgressInfo[index].id, secondID: routePointsProgressInfo[index + 1].id)
                let isFinished = routePointsProgressInfo[index].isFinished && routePointsProgressInfo[index + 1].isFinished
                let routeFragmentProgressInfo = ManageRouteMap.RouteFragmentProgressInfo(type: .routeFragment,
                                                                                         id: id, isFinished: isFinished)
                
                routeFragmentsProgressInfo.append(routeFragmentProgressInfo)
            }
            
            return routeFragmentsProgressInfo
        } else {
            return []
        }
    }
    
    private func updateAnnotationInfo(with routePointsProgressInfo: [ProgressInfo]) {
        var newAnnotationsInfo: [AnnotationInfo] = []
        
        for routePointProgressInfo in routePointsProgressInfo {
            let index = annotationsInfo.firstIndex(where: { $0.id == routePointProgressInfo.id })
            
            if let index = index {
                var annotationInfo = annotationsInfo[index]
                annotationsInfo.remove(at: index)
                
                annotationInfo.isFinished = routePointProgressInfo.isFinished
                annotationsInfo.append(annotationInfo)
            }
        }
    }
    
    // MARK: - Set route point
    
    func setRoutePoint(request: ManageRouteMap.SetRoutePoint.Request) {
        let response = ManageRouteMap.SetRoutePoint.Response(annotationInfo: request.annotationInfo)
        presenter?.presentSetRoutePoint(response: response)
    }
    
    // MARK: Select Annotation
    
    func selectAnnotation(request: ManageRouteMap.SelectAnnotation.Request) {
        idOfSelectedAnnotation = request.identifier
        let response = ManageRouteMap.SelectAnnotation.Response(identifier: idOfSelectedAnnotation, coordinate: request.coordinate)
        presenter?.presentSelectAnnotation(response: response)
    }
    
    // MARK: Deselect Annotation
    
    func deselectAnnotation(request: ManageRouteMap.DeselectAnnotation.Request) {
        selectedRoutePoint = nil
        let response = ManageRouteMap.DeselectAnnotation.Response()
        presenter?.presentDeselectAnnotation(response: response)
    }
    
    // MARK: Show Detail
    
    func showDetail(request: ManageRouteMap.ShowDetail.Request) {
        let response = ManageRouteMap.ShowDetail.Response()
        presenter?.presentShowDetail(response: response)
    }
    
    // MARK: Edit Route Point
    
    var routePointToEdit: RoutePoint?
    
    func editRoutePoint(request: ManageRouteMap.EditRoutePoint.Request) {
        if routePointToEdit != nil {
            let response = ManageRouteMap.EditRoutePoint.Response()
            presenter?.presentEditRoutePoint(response: response)
        }
    }
    
    // MARK: Delete Annotation
    
    func deleteRoutePoint(request: ManageRouteMap.DeleteAnnotation.Request) {
        let response = ManageRouteMap.DeleteAnnotation.Response(identifier: request.identifier)
        presenter?.presentDeleteRoutePoint(response: response)
    }
    
    // MARK: Create Route Fragment
    
    /**
     Initialized in constructor with empty array.
     Is updating in Create Route Fragment use case (insert) and Delete Route Fragment use case (delete).
     */
    var routeFragments: [RouteFragment]
    
    func createRouteFragment(request: ManageRouteMap.CreateRouteFragment.Request) {
        let startCoordinate = CLLocationCoordinate2D(
            latitude: request.addedSubrouteInfo.startWaypoint.latitude, longitude: request.addedSubrouteInfo.startWaypoint.longitude)
        let endCoordinate = CLLocationCoordinate2D(
            latitude: request.addedSubrouteInfo.endWaypoint.latitude, longitude: request.addedSubrouteInfo.endWaypoint.longitude)
        routeCreator.calculateRoute(from: startCoordinate, to: endCoordinate, drawHandler: { routeInfo in
            if let routeInfo = routeInfo {
                let startPointID = request.addedSubrouteInfo.startWaypoint.id
                let endPointID = request.addedSubrouteInfo.endWaypoint.id
                let isFinished = request.addedSubrouteInfo.startWaypoint.isFinished && request.addedSubrouteInfo.endWaypoint.isFinished
                let routeFragment = ConcreteRouteFragment(startPointID: startPointID, endPointID: endPointID,
                                                          coordinates: routeInfo.coordinates,
                                                          travelTimeInSeconds: routeInfo.timeInSeconds,
                                                          travelDistanceInMeters: routeInfo.distanceInMeters,
                                                          isFinished: isFinished)
                self.routeFragments.append(routeFragment)
                
                self.worker?.insert(routeFragment: routeFragment)
                
                let response = ManageRouteMap.CreateRouteFragment.Response(routeFragment: routeFragment)
                self.presenter?.presentCreateRouteFragment(response: response)
            } // We don't check else because impossibility of route creation is checked before in Create Route Point use case.
            
        })
    }
    
    // MARK: Add Route Fragment
    
    func addRouteFragment(request: ManageRouteMap.AddRouteFragment.Request) {
        presenter?.presentAddedRouteFragment(response: .init(routeFragment: request.routeFragment))
    }
    
    // MARK: Delete Route Fragment
    
    func deleteRouteFragment(request: ManageRouteMap.DeleteRouteFragment.Request) {
        let indexToRemove = routeFragments.firstIndex(where: { return $0.identifier == request.identifier })
        
        if let index = indexToRemove {
            routeFragments.remove(at: index)
            let response = ManageRouteMap.DeleteRouteFragment.Response(identifier: request.identifier)
            presenter?.presentDeleteRouteFragment(response: response)
        }
    }
    
    // MARK: Map Route
    
    func mapRoute(request: ManageRouteMap.MapRoute.Request) {
        var addedSubroutesInfo: [ManageRouteMap.MapRoute.SubrouteInfo] = []
        let addedAnnotationsInfo = request.addedAnnotationsInfo.sorted(by: { return $0.orderNumber < $1.orderNumber})
        if addedAnnotationsInfo.count > 0 {
            for annotationInfo in addedAnnotationsInfo {
                if let previousAnnotationInfo = getPreviousAnnotationInfo(within: annotationsInfo, by: annotationInfo.orderNumber) {
                    let subrouteInfo = createSubrouteInfo(start: previousAnnotationInfo, end: annotationInfo)
                    addedSubroutesInfo.append(subrouteInfo)
                }
            }
        }
        
        var idOfDeletedRouteFragments: [String] = []
        
        // There's huge problem. If we delete several points between some other points route won't be reconstructed
        // and empty gap will be remained. Now it isn't a problem but if we want delete several points (not all of them but more than two)
        // we should implement this behaviour.
        for annotationInfo in request.removedAnnotationsInfo {
            let orderNumber = annotationInfo.orderNumber
            
            let previousAnnotationInfo = getPreviousAnnotationInfo(within: annotationsInfo, by: orderNumber)
            if let idOfPreviousPoint = previousAnnotationInfo?.id {
                let routeFragmentID = format(firstID: idOfPreviousPoint, secondID: annotationInfo.id)
                
                if !idOfDeletedRouteFragments.contains(routeFragmentID) {
                    idOfDeletedRouteFragments.append(routeFragmentID)
                }
            } else {
                // Check previous point within deleted route points in removedAnnotationsInfo array.
                let previousPoint = getPreviousAnnotationInfo(within: request.removedAnnotationsInfo, by: orderNumber)
                if let idOfPreviousPoint = previousPoint?.id {
                    let routeFragmentID = format(firstID: idOfPreviousPoint, secondID: annotationInfo.id)
                    
                    if !idOfDeletedRouteFragments.contains(routeFragmentID) {
                        idOfDeletedRouteFragments.append(routeFragmentID)
                    }
                }
            }
            
            let nextAnnotationInfo = getNextAnnotationInfo(within: annotationsInfo, by: orderNumber)
            if let idOfNextPoint = nextAnnotationInfo?.id {
                let routeFragmentID = format(firstID: annotationInfo.id, secondID: idOfNextPoint)
                
                if !idOfDeletedRouteFragments.contains(routeFragmentID) {
                    idOfDeletedRouteFragments.append(routeFragmentID)
                }
            } else {
                // Check next point within deleted route points in removedAnnotationsInfo array.
                let nextPoint = getNextAnnotationInfo(within: request.removedAnnotationsInfo, by: orderNumber)
                if let idOfNextPoint = nextPoint?.id {
                    let routeFragmentID = format(firstID: annotationInfo.id, secondID: idOfNextPoint)
                    
                    if !idOfDeletedRouteFragments.contains(routeFragmentID) {
                        idOfDeletedRouteFragments.append(routeFragmentID)
                    }
                }
            }
            
            if let startPoint = previousAnnotationInfo, let endPoint = nextAnnotationInfo {
                let subrouteInfoForGap = createSubrouteInfo(start: startPoint, end: endPoint)
                addedSubroutesInfo.append(subrouteInfoForGap)
            }
        }
        let response = ManageRouteMap.MapRoute.Response(addedSubroutesInfo: addedSubroutesInfo,
                                                        idsOfDeletedRouteFragments: idOfDeletedRouteFragments)
        presenter?.presentMapRoute(response: response)
    }
    
    private func getPreviousAnnotationInfo(within annotationsInfoToSearchIn: [AnnotationInfo], by orderNumber: Int) -> AnnotationInfo? {
        let filteredAnnotationInfo = annotationsInfoToSearchIn.sorted(by: { lhs, rhs in
            return lhs.orderNumber > rhs.orderNumber
            }).filter({ return $0.orderNumber < orderNumber }).first
        
        if let filteredOrderNumber = filteredAnnotationInfo?.orderNumber, filteredOrderNumber < orderNumber {
            return filteredAnnotationInfo
        } else {
            return nil
        }
    }
    
    private func getNextAnnotationInfo(within annotationsInfoToSearchIn: [AnnotationInfo], by orderNumber: Int) -> AnnotationInfo? {
        let filteredAnnotationInfo = annotationsInfoToSearchIn.sorted(by: { lhs, rhs in
            return lhs.orderNumber < rhs.orderNumber
            }).filter({ return $0.orderNumber > orderNumber }).first
        
        if let filteredOrderNumber = filteredAnnotationInfo?.orderNumber, filteredOrderNumber > orderNumber {
            return filteredAnnotationInfo
        } else {
            return nil
        }
    }
    
    private func createSubrouteInfo(start: AnnotationInfo, end: AnnotationInfo) -> ManageRouteMap.MapRoute.SubrouteInfo {
        let startWaypoint = ManageRouteMap.MapRoute.Waypoint(
            id: start.id,
            latitude: start.latitude, longitude: start.longitude,
            isFinished: start.isFinished)
        let endWaypoint = ManageRouteMap.MapRoute.Waypoint(
            id: end.id,
            latitude: end.latitude, longitude: end.longitude,
            isFinished: end.isFinished)
        let subrouteInfo = ManageRouteMap.MapRoute.SubrouteInfo(startWaypoint: startWaypoint, endWaypoint: endWaypoint)
        
        return subrouteInfo
    }
    
    // MARK: Clear All
    
    func clearAll(request: ManageRouteMap.ClearAll.Request) {
        worker?.deleteAllEntries()
        let response = ManageRouteMap.ClearAll.Response()
        presenter?.presentClearAll(response: response)
    }
    
    // MARK: Toggle User Input
    
    func toggleUserInput(request: ManageRouteMap.ToggleUserInput.Request) {
        let response = ManageRouteMap.ToggleUserInput.Response(isLocked: request.isLocked)
        presenter?.presentToggleUserInput(response: response)
    }
    
    // MARK: Focus
    
    func focus(request: ManageRouteMap.Focus.Request) {
        let routeExists = !annotationsInfo.isEmpty
        presenter?.presentFocus(response: .init(routeExists: routeExists))
    }
    
    // MARK: Focus On Route
    
    func focusOnRoute(request: ManageRouteMap.FocusOnRoute.Request) {
        let coordinates = prepareAllCoordinatesArray()
        
        do {
            let (locSouthWest, locNorthEast) = try getCornerCoordinates(from: coordinates)
            let response = ManageRouteMap.FocusOnRoute.Response(southWestCoordinate: locSouthWest, northEastCoordinate: locNorthEast)
            presenter?.presentFocusOnRoute(response: response)
        } catch {
            print(error)
        }
    }
    
    private func prepareAllCoordinatesArray() -> [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        
        for annotationInfo in annotationsInfo {
            let coordinate = CLLocationCoordinate2D(latitude: annotationInfo.latitude, longitude: annotationInfo.longitude)
            coordinates.append(coordinate)
        }
        
        for routeFragment in routeFragments {
            for coordinate in routeFragment.coordinates {
                coordinates.append(coordinate)
            }
        }
        
        return coordinates
    }
    
    // MARK: Focus On User
    
    func focusOnUser(request: ManageRouteMap.FocusOnUser.Request) {
        let response = ManageRouteMap.FocusOnUser.Response(userCoordinate: request.userCoordinate)
        presenter?.presentFocusOnUser(response: response)
    }
    
    // MARK: Focus On Coordinates
    
    func focusOnCoordinates(request: ManageRouteMap.FocusOnCoordinates.Request) {
        do {
            let (locSouthWest, locNorthEast) = try getCornerCoordinates(from: request.coordinates)
            let response = ManageRouteMap.FocusOnCoordinates.Response(southWestCoordinate: locSouthWest, northEastCoordinate: locNorthEast)
            presenter?.presentFocusOnCoordinates(response: response)
        } catch {
            print(error)
        }
    }
    
    // MARK: Route Estimation
    
    func routeEstimation(request: ManageRouteMap.RouteEstimation.Request) {
        var timeInSeconds = 0
        var distanceInMeters = 0
        
        for routeFragment in routeFragments {
            timeInSeconds += routeFragment.travelTimeInSeconds
            distanceInMeters += routeFragment.travelDistanceInMeters
        }
        
        let response = ManageRouteMap.RouteEstimation.Response(timeInSeconds: timeInSeconds, distanceInMeters: distanceInMeters)
        presenter?.presentRouteEstimation(response: response)
    }
    
    // MARK: Create Temprorary Point
    
    func createTemporaryPoint(request: ManageRouteMap.CreateTemporaryPoint.Request) {
        presenter?.presentTemporaryPoint(response: .init(coordinate: request.coordinate, title: request.title))
    }
    
    // MARK: Remove Temporary Point
    
    func removeTemporaryPoint(request: ManageRouteMap.RemoveTemporaryPoint.Request) {
        presenter?.presentTemporaryPointDeletion(response: .init())
    }
    
    // MARK: - Shared Methods
    
    enum CornersEstimationError: Error {
        case emptyArray
        case invalidAnnotations
    }
    
    private func getCornerCoordinates(from coordinates: [CLLocationCoordinate2D]) throws -> (CLLocationCoordinate2D, CLLocationCoordinate2D) {
        if coordinates.count == 0 {
            throw CornersEstimationError.emptyArray
        }
        
        var minimalCoordinate = CLLocationCoordinate2D()
        var maximalCoordinate = CLLocationCoordinate2D()
        var minMaxInitialized = false
        var numberOfValidAnnotations = 0

        for coordinate in coordinates {
            
            if !minMaxInitialized {
                minimalCoordinate = coordinate;
                maximalCoordinate = coordinate;
                minMaxInitialized = true;
            } else {
                minimalCoordinate.latitude = min( minimalCoordinate.latitude, coordinate.latitude )
                minimalCoordinate.longitude = min(minimalCoordinate.longitude, coordinate.longitude )

                maximalCoordinate.latitude = max( maximalCoordinate.latitude, coordinate.latitude )
                maximalCoordinate.longitude = max( maximalCoordinate.longitude, coordinate.longitude )
            }
            numberOfValidAnnotations += 1
        }
        
        if numberOfValidAnnotations == 0 {
            throw CornersEstimationError.invalidAnnotations
        }
        
        let locSouthWest = CLLocationCoordinate2D(latitude: minimalCoordinate.latitude, longitude: minimalCoordinate.longitude)
        let locNorthEast = CLLocationCoordinate2D(latitude: maximalCoordinate.latitude, longitude: maximalCoordinate.longitude)
        
        return (locSouthWest, locNorthEast)
    }
}
