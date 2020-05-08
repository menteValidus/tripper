//
//  CoreDataDAO.swift
//  Tripper
//
//  Created by Denis Cherniy on 11.02.2020.
//  Copyright © 2020 Denis Cherniy. All rights reserved.
//

import CoreData

class CoreDatestore: RoutePointDataStore {
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: DataModelDB.name)
        container.loadPersistentStores(completionHandler: { storeDescription, error in
            if let error = error {
                throwAn(error: error)
            }
        })
        
        return container
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = persistentContainer.viewContext
    
    
    struct DataModelDB {
        static let name = "DataModel"
        
        struct Entities {
            
            struct RoutePointEntity {
                static let name = "RoutePointEntity"
                
                struct KeyPathNames {
                    static let id = "id"
                    static let longitude = "longitude"
                    static let latitude = "latitude"
                    static let orderNumber = "orderNumber"
                    static let title = "title"
                    static let subtitle = "subtitle"
                    static let arrivalDate = "arrivalDate"
                    static let departureDate = "departureDate"
                    static let distanceToNextPointInMeters = "distanceToNextPointInMeters"
                    static let timeToNextPointInSeconds = "timeToNextPointInSeconds"
                }
            }
            
            struct RouteFragmentEntity {
                static let name = "RouteFragmentEntity"
                
                struct KeyPathNames {
                    static let id = "id"
                    static let coordinates = "coordinates"
                    static let time = "timeInSeconds"
                    static let distance = "distanceInMeters"
                }
            }
                
        }
    }
    
    // MARK: - Database's Queries
    
    func fetch(with identifier: String) -> RoutePoint? {
        let pointFetch = NSFetchRequest<NSFetchRequestResult>(entityName: DataModelDB.Entities.RoutePointEntity.name)
        let predicate = NSPredicate(format: "\(DataModelDB.Entities.RoutePointEntity.KeyPathNames.id) = %@", identifier)
        pointFetch.predicate = predicate
        
        let fetchedPoint: RoutePointEntity?
        do {
            fetchedPoint = try (managedObjectContext.fetch(pointFetch) as! [RoutePointEntity]).first
        } catch {
            fatalError("*** Failed to fetch RoutePoint with id: \(identifier).\n\(error)")
        }
        
        if let routePointEntity = fetchedPoint {
            let routePoint: RoutePoint = convertEntityToRoutePoint(routePointEntity)
            return routePoint
        } else {
            return nil
        }
    }
    
    func fetchAll() -> [RoutePoint] {
        let pointsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: DataModelDB.Entities.RoutePointEntity.name)
        let fetchedPoints: [RoutePointEntity]
        do {
            fetchedPoints = try managedObjectContext.fetch(pointsFetch) as! [RoutePointEntity]
        } catch {
            fatalError("*** Failed to fetch all RoutePoint's date.\n\(error)")
        }
        
        var routePoints: [RoutePoint] = []
        
        for pointEntity in fetchedPoints {
            routePoints.append(convertEntityToRoutePoint(pointEntity))
        }
        
        return routePoints
    }
    
    func insert(_ point: RoutePoint) {
        let entity = NSEntityDescription.entity(forEntityName: DataModelDB.Entities.RoutePointEntity.name, in: managedObjectContext)!
        
        let routePointObject = NSManagedObject(entity: entity, insertInto: managedObjectContext) as! RoutePointEntity
        configure(entity: routePointObject, with: point)
        
        do {
            try managedObjectContext.save()
        } catch {
            throwAn(error: error)
        }
        
    }
    
    func update(_ point: RoutePoint) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> =
            NSFetchRequest.init(entityName: DataModelDB.Entities.RoutePointEntity.name)
        fetchRequest.predicate = NSPredicate(format: "id = %@", point.id)
        do {
            let fetchResult = try managedObjectContext.fetch(fetchRequest)
            
            if let pointToUpdate = fetchResult.first as? RoutePointEntity {
                configure(entity: pointToUpdate, with: point)
                try managedObjectContext.save()
            } else {
                fatalError("There is no way we can be here!!!")
            }
        } catch {
            fatalError("Update's Error: \(error)")
        }
    }
    
    func delete(_ point: RoutePoint) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> =
            NSFetchRequest.init(entityName: DataModelDB.Entities.RoutePointEntity.name)
        fetchRequest.predicate = NSPredicate(format: "id = %@", point.id)
        
        do {
            let fetchResult = try managedObjectContext.fetch(fetchRequest)
            
            let pointToDelete = fetchResult.first as! RoutePointEntity
            managedObjectContext.delete(pointToDelete)
            
            try managedObjectContext.save()
            
        } catch {
            fatalError("Delete's Error: \(error)")
        }
    }
    
    func deleteAll() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: DataModelDB.Entities.RoutePointEntity.name)
        
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try managedObjectContext.execute(batchDeleteRequest)
        } catch {
            fatalError("Clear's Error: \(error)")
        }
    }
    
    // MARK: - Converters
    
    private func convertEntityToRoutePoint(_ entity: RoutePointEntity) -> RoutePoint {
        let point = RoutePoint(
            id: entity.id!, orderNumber: Int(entity.orderNumber),
            title: entity.title ?? "", subtitle: entity.subtitle ?? "",
            latitude: entity.latitude, longitude: entity.longitude,
            arrivalDate: entity.arrivalDate, departureDate: entity.departureDate,
            timeToNextPointInSeconds: Int(entity.timeToNextPointInSeconds),
            distanceToNextPointInMeters: Int(entity.distanceToNextPointInMeters))
        return point
    }
    
    private func configure(entity: RoutePointEntity, with routePoint: RoutePoint) {
        entity.setValue(routePoint.id, forKey: DataModelDB.Entities.RoutePointEntity.KeyPathNames.id)
        entity.setValue(routePoint.longitude, forKey: DataModelDB.Entities.RoutePointEntity.KeyPathNames.longitude)
        entity.setValue(routePoint.latitude, forKey: DataModelDB.Entities.RoutePointEntity.KeyPathNames.latitude)
        entity.setValue(routePoint.orderNumber, forKey: DataModelDB.Entities.RoutePointEntity.KeyPathNames.orderNumber)
        entity.setValue(routePoint.title, forKey: DataModelDB.Entities.RoutePointEntity.KeyPathNames.title)
        entity.setValue(routePoint.subtitle, forKey: DataModelDB.Entities.RoutePointEntity.KeyPathNames.subtitle)
        entity.setValue(routePoint.arrivalDate, forKey: DataModelDB.Entities.RoutePointEntity.KeyPathNames.arrivalDate)
        entity.setValue(routePoint.departureDate, forKey: DataModelDB.Entities.RoutePointEntity.KeyPathNames.departureDate)
        entity.setValue(routePoint.timeToNextPointInSeconds, forKey: DataModelDB.Entities.RoutePointEntity.KeyPathNames.timeToNextPointInSeconds)
        entity.setValue(routePoint.distanceToNextPointInMeters, forKey: DataModelDB.Entities.RoutePointEntity.KeyPathNames.distanceToNextPointInMeters)
    }
    
}

extension CoreDatestore: OrderNumberGenerator {
    // MARK: - Order Number Generator
    
    func getNewOrderNumber() -> Int {
        let maxOrderNumber = fetchMaxOrderNumber()
        
        return Int(maxOrderNumber) + 1
    }
    
    private func fetchMaxOrderNumber() -> Int32 {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: DataModelDB.Entities.RoutePointEntity.name)
        
        let sortDesctiptor = NSSortDescriptor(key: DataModelDB.Entities.RoutePointEntity.KeyPathNames.orderNumber, ascending: false)
        fetchRequest.sortDescriptors = [sortDesctiptor]
        fetchRequest.fetchLimit = 1

        do {
            let fetchResult = try managedObjectContext.fetch(fetchRequest)
            
            if let routePointEntity = fetchResult.first as? RoutePointEntity {
                return routePointEntity.orderNumber
            } else {
                return 0
            }
        } catch {
            fatalError("*** Failed to fetch max order number with error = \(error)")
        }
    }
}

extension CoreDatestore: DateLimiter {
    // MARK: - Date Limiter
    
    func fetchLeftLimit(by orderNumber: Int) -> Date? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: DataModelDB.Entities.RoutePointEntity.name)
        
        let predicate =
            NSPredicate(format: "\(DataModelDB.Entities.RoutePointEntity.KeyPathNames.orderNumber) < %d", orderNumber)
        fetchRequest.predicate = predicate
        
        let sortDesctiptor = NSSortDescriptor(key: DataModelDB.Entities.RoutePointEntity.KeyPathNames.orderNumber, ascending: true)
        fetchRequest.sortDescriptors = [sortDesctiptor]
        fetchRequest.fetchLimit = 1

        do {
            let fetchResult = try managedObjectContext.fetch(fetchRequest)
            
            if let routePointEntity = fetchResult.last as? RoutePointEntity {
                let timeIntervalToAdd = TimeInterval(routePointEntity.timeToNextPointInSeconds)
                return routePointEntity.departureDate.addingTimeInterval(timeIntervalToAdd)
            } else {
                return nil
            }
        } catch {
            fatalError("*** Failed to fetch left date limit with error = \(error)")
        }
    }
    
    func fetchRightLimit(by orderNumber: Int) -> Date? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: DataModelDB.Entities.RoutePointEntity.name)
        
        let predicate =
            NSPredicate(format: "\(DataModelDB.Entities.RoutePointEntity.KeyPathNames.orderNumber) > %d", orderNumber)
        fetchRequest.predicate = predicate
        
        let sortDesctiptor = NSSortDescriptor(key: DataModelDB.Entities.RoutePointEntity.KeyPathNames.orderNumber, ascending: true)
        fetchRequest.sortDescriptors = [sortDesctiptor]
        fetchRequest.fetchLimit = 1

        do {
            let fetchResult = try managedObjectContext.fetch(fetchRequest)
            
            if let routePointEntity = fetchResult.first as? RoutePointEntity {
                return routePointEntity.arrivalDate
            } else {
                return nil
            }
        } catch {
            fatalError("*** Failed to fetch right date limit with error = \(error)")
        }
    }
    
}
