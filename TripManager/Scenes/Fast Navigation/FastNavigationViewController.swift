//
//  FastNavigationViewController.swift
//  Tripper
//
//  Created by Denis Cherniy on 19.05.2020.
//  Copyright (c) 2020 Denis Cherniy. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit
import CoreLocation
import Swinject

protocol FastNavigationDisplayLogic: class {
    func displayFetchedData(viewModel: FastNavigation.FetchData.ViewModel)
    func displaySelectedSubroute(viewModel: FastNavigation.SelectSubroute.ViewModel)
}



protocol SidePopup: DismissablePopup {
    var width: CGFloat { get }
}

class FastNavigationViewController: UIViewController {
    var interactor: FastNavigationBusinessLogic?
    var router: (FastNavigationRoutingLogic & FastNavigationDataPassing)?
    
    @IBOutlet weak var tableView: UITableView!
    
    var subroutes: [Subroute] = []
    var delegate: HasFocusableMap?
    
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
        let interactor = FastNavigationInteractor()
        let presenter = FastNavigationPresenter()
        let router = FastNavigationRouter()
        let worker = FastNavigationWorker(routePointGateway: Container.shared.resolve(RoutePointGateway.self)!,
                                          routeFragmentGateway: Container.shared.resolve(RouteFragmentGateway.self)!)
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        interactor.worker = worker
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDelegates()
        fetchData()
    }
    
    // MARK: Actions
    
    @IBAction func backArrowTapped(_ sender: Any) {
        router?.routeToManageRouteMap(segue: nil)
    }
}

extension FastNavigationViewController {
    // MARK: - Configurators
    
    func configureDelegates() {
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension FastNavigationViewController: FastNavigationDisplayLogic {
    // MARK: - Fetch Data
    
    func fetchData() {
        interactor?.fetchData(request: .init())
    }
    
    func displayFetchedData(viewModel: FastNavigation.FetchData.ViewModel) {
        subroutes = viewModel.subroutes
        tableView.reloadData()
        print("*** \(viewModel.subroutes)")
    }
    
    // MARK: Select Subroute
    
    func displaySelectedSubroute(viewModel: FastNavigation.SelectSubroute.ViewModel) {
        delegate?.focusableMap(didSelected: viewModel.coordinates)
    }
}

extension FastNavigationViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        subroutes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = subroutes[indexPath.row].title
        
        return cell
    }

}

extension FastNavigationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        interactor?.selectSubroute(request: .init(index: indexPath.row))
    }
}

extension FastNavigationViewController: SidePopup {
    var width: CGFloat {
        return view.frame.width
    }
    
    func dismissPopup() {
        router?.routeToManageRouteMap(segue: nil)
    }
}
