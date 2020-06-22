//
//  DetailRoutePointViewController.swift
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
import MapKit
import Swinject

protocol DetailRoutePointDisplayLogic: class {
    func displaySetupUI(viewModel: DetailRoutePoint.SetupUI.ViewModel)
    func displayDismiss(viewModel: DetailRoutePoint.Dismiss.ViewModel)
    func displayEdit(viewModel: DetailRoutePoint.Edit.ViewModel)
    func displayDelete(viewModel: DetailRoutePoint.Delete.ViewModel)
    func displayToggleView(viewModel: DetailRoutePoint.ToggleView.ViewModel)
    func displayLaunchedNavigator(viewModel: DetailRoutePoint.LaunchNavigator.ViewModel)
    func displayFinishedMilestone(viewModel: DetailRoutePoint.FinishMilestone.ViewModel)
}

typealias Popup = DismissablePopup & ChangeablePopup

protocol DismissablePopup: class {
    func dismissPopup()
}

protocol ChangeablePopup: class {
    var state: PopupCoverage { get }
    func updateUI()
}

enum PopupCoverage: Float {
    case mostPart = 0.5
    case smallPart = 0.25
    case toDismiss = 0
}

class DetailRoutePointViewController: UIViewController, DetailRoutePointDisplayLogic {
    var interactor: DetailRoutePointBusinessLogic?
    var router: (NSObjectProtocol & DetailRoutePointRoutingLogic & DetailRoutePointDataPassing)?
    
    var state: PopupCoverage = .smallPart
    
    private var panGestureRecognizer: UIPanGestureRecognizer?
    
    // MARK: Object lifecycle
    
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
        let interactor = DetailRoutePointInteractor()
        let presenter = DetailRoutePointPresenter()
        let router = DetailRoutePointRouter()
        let worker = DetailRoutePointWorker(routePointGateway: Container.shared.resolve(RoutePointGateway.self)!)
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
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initGestureRecognizers()
        initView()
        setupUI()
    }
    
    private func initView() {
        self.view.layer.cornerRadius = 32
    }
    
    private func initGestureRecognizers() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DetailRoutePointViewController.onPan(recognizer:)))
        view.addGestureRecognizer(panGestureRecognizer!)
    }
    
    // MARK: - Setup UI
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var arrivalDateLabel: UILabel!
    @IBOutlet weak var departureDateLabel: UILabel!
    
    func setupUI() {
        updateUI()
    }
    
    func displaySetupUI(viewModel: DetailRoutePoint.SetupUI.ViewModel) {
        titleLabel.text = viewModel.title
        descriptionTextView.text = viewModel.description
        arrivalDateLabel.text = viewModel.arrivalDateText
        departureDateLabel.text = viewModel.departureDateText
        isFinishedButton.isSelected = viewModel.isFinished
    }
    
    // MARK: Dismiss
    
    func displayDismiss(viewModel: DetailRoutePoint.Dismiss.ViewModel) {
        router?.routeToManageRouteMap(segue: nil)
    }
    
    // MARK: Edit
    
    @IBAction func editRoutePoint() {
        let request = DetailRoutePoint.Edit.Request()
        interactor?.edit(request: request)
    }
    
    func displayEdit(viewModel: DetailRoutePoint.Edit.ViewModel) {
        router?.routeToManageRouteMapWithEdit(segue: nil)
    }
    
    // MARK: Delete
    
    @IBAction func deleteRoutePoint() {
        let request = DetailRoutePoint.Delete.Request()
        interactor?.delete(request: request)
    }
    
    func displayDelete(viewModel: DetailRoutePoint.Delete.ViewModel) {
        router?.routeToManageRouteMapWithDelete(segue: nil)
    }
    
    // MARK: Toggle View
    
    func displayToggleView(viewModel: DetailRoutePoint.ToggleView.ViewModel) {
        state = viewModel.screenCoverage
        let percent = CGFloat(viewModel.screenCoverage.rawValue)
        if percent > 0 {
            UIView.animate(withDuration: 0.3) {
                let height: CGFloat = self.view.frame.height
                let width  = self.view.frame.width
                let yCoordinate = height * (1 - percent)
                print(Float(yCoordinate))
                self.view.frame = CGRect(x: 0, y: yCoordinate, width: width, height: height)
            }
        } else {
            dismissPopup()
        }
    }
    
    // MARK: Launch Navigator
    
    @IBAction func launchNavigator() {
        interactor?.launchNavigator(request: .init())
    }
    
    func displayLaunchedNavigator(viewModel: DetailRoutePoint.LaunchNavigator.ViewModel) {
        let regionDistance: CLLocationDistance = 1000
        let region = MKCoordinateRegion(center: viewModel.coordinate,
                                        latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        
        let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: region.center),
                       MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: region.span)]
        
        let placemark = MKPlacemark(coordinate: region.center)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = viewModel.title
        mapItem.openInMaps(launchOptions: options)
    }
    
    // MARK: Finish Milestone
    
    @IBOutlet weak var isFinishedButton: UIButton!
    
    @IBAction func isFinishButtonTapped(_ sender: Any) {
        interactor?.finishMilestone(request: .init(isFinished: !isFinishedButton.isSelected))
    }
    
    func displayFinishedMilestone(viewModel: DetailRoutePoint.FinishMilestone.ViewModel) {
        isFinishedButton.isSelected = viewModel.isFinished
    }
}

extension DetailRoutePointViewController {
    // MARK: - Gesture Actions
    
    @objc func onPan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            let translation = recognizer.translation(in: self.parent!.view)
            let y = view.frame.minY
            if let superViewHeight = self.parent?.view.frame.height {
                if !(superViewHeight - view.frame.height > y + translation.y) {
                    self.view.frame = CGRect(x: 0, y: y + translation.y, width: view.frame.width, height: view.frame.height)
                }
            }
            recognizer.setTranslation(.zero, in: self.view)
            break
            
        case .cancelled, .ended:
            let positionFromTheTop = view.frame.origin.y
            let maxDistanceToPan = view.frame.height
            let request = DetailRoutePoint.ToggleView.Request(positionFromTheTop: positionFromTheTop, maxDistanceToPan: maxDistanceToPan)
            interactor?.toggleView(request: request)
            
        default:
            return
        }
    }
    
    func toggleView(screenCoverage percent: CGFloat) {
        UIView.animate(withDuration: 0.3) {
            let height = self.view.frame.height
            let width  = self.view.frame.width
            let yCoordinate = self.view.frame.height * (1 - percent)
            print(Float(yCoordinate))
            self.view.frame = CGRect(x: 0, y: yCoordinate, width: width, height: height)
        }
    }
}

extension DetailRoutePointViewController: DismissablePopup {
    // MARK: - Dismissable Popup
    
    func dismissPopup() {
        let request = DetailRoutePoint.Dismiss.Request()
        interactor?.dismiss(request: request)
    }
}

extension DetailRoutePointViewController: ChangeablePopup {
    
    // MARK: - Changeable Popup
    
    func updateUI() {
        let request = DetailRoutePoint.SetupUI.Request()
        interactor?.setupUI(request: request)
    }
}
