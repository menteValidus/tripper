//
//  ListRouteViewController.swift
//  Tripper
//
//  Created by Denis Cherniy on 16.04.2020.
//  Copyright (c) 2020 Denis Cherniy. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit
import Swinject

protocol ListRouteDisplayLogic: class {
    func displayFetchData(viewModel: ListRoute.FetchData.ViewModel)
}

class ListRouteViewController: UITableViewController, ListRouteDisplayLogic {
    var interactor: ListRouteBusinessLogic?
    var router: (NSObjectProtocol & ListRouteRoutingLogic & ListRouteDataPassing)?
    
    // MARK: Object Lifecycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: Setup
    
    private func setup() {
        let viewController = self
        let interactor = ListRouteInteractor()
        let presenter = ListRoutePresenter()
        let router = ListRouteRouter()
        let worker = ListRouteWorker(routePointGateway: Container.shared.resolve(RoutePointDataStore.self)!)
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        interactor.worker = worker
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    // MARK: Routing
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let scene = segue.identifier {
            let selector = NSSelectorFromString("routeTo\(scene)WithSegue:")
            if let router = router, router.responds(to: selector) {
                router.perform(selector, with: segue)
            }
        }
    }
    
    // MARK: View Lifecycle
    
    struct TableView {
        struct CellIdentifiers {
            static let roadCell = "RoadCell"
            static let stayingCell = "StayingCell"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var cellNib = UINib(nibName: TableView.CellIdentifiers.roadCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIdentifiers.roadCell)
        
        cellNib = UINib(nibName: TableView.CellIdentifiers.stayingCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIdentifiers.stayingCell)
        
        fetchData()
    }
    
    // MARK: Table View's Delegate
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subroutes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let anotherSubroute = subroutes[indexPath.row]
        
        switch anotherSubroute {
        case is ListRoute.InRoad:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.roadCell, for: indexPath) as! RoadCell
            cell.configure(for: anotherSubroute as! ListRoute.InRoad)
            
            return cell
            
        case is ListRoute.Staying:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifiers.stayingCell, for: indexPath) as! StayingCell
            cell.configure(for: anotherSubroute as! ListRoute.Staying)
            
            return cell
            
        default:
            fatalError("*** It's impossible to be here!")
        }
        
    }
    
    var selectedRow: Int?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row % 2 == 0 {
            if indexPath.row == selectedRow {
                selectedRow = nil
            } else {
                selectedRow = indexPath.row
            }
            
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
   
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if selectedRow == indexPath.row {
            return 132.0
        } else {
            return 44.0
        }
        
    }
    
    // MARK: - Fetch Data
    
    var subroutes = [Subroute]()
    
    func fetchData() {
        let request = ListRoute.FetchData.Request()
        interactor?.fetchData(request: request)
    }
    
    func displayFetchData(viewModel: ListRoute.FetchData.ViewModel) {
        subroutes = viewModel.subroutes
        tableView.reloadData()
    }
}
