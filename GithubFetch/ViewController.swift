//
//  ViewController.swift
//  GithubFetch
//
//  Created by Anton Tugolukov on 4/3/23.
//

import UIKit
import Combine

let kOrgsCellId = "OrgsCell"

class OrgsCell : UITableViewCell {
    
//    private let logo: UIImageView = {
//        let iv = UIImageView()
//        iv.backgroundColor = UIColor.green
//        return iv
//    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        //contentView.addSubview(logo)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        let sideLength = contentView.frame.size.height - 10
//        logo.frame = CGRect(origin: CGPointMake(5, 5), size: CGSizeMake(sideLength, sideLength))
//
//    }
    
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var observer : AnyCancellable?
    var organizations : [OrgInfo] = []
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return organizations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: kOrgsCellId, for: indexPath) as? OrgsCell else {
            fatalError("Cannot get cell with id \(kOrgsCellId)")
        }
        let org = organizations[indexPath.row]
        let orgDetail = DataStore.persistedDetails(orgLogin: org.login)
        
        cell.textLabel?.text = orgDetail?.name ?? org.login
        cell.detailTextLabel?.text = org.description
        cell.imageView?.image = OrgsLogoCache.shared.cachedLogoForOrg(org: org)
        cell.backgroundColor = indexPath.row % 2 == 0 ? UIColor.darkGray : UIColor.orange
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let org = organizations[indexPath.row]
        if let homepageURL = DataStore.persistedDetails(orgLogin: org.login)?.htmlUrl {
            UIApplication.shared.open(URL(string: homepageURL)!)
        }
    }
    
    
    private let organizationsView: UITableView = {
        let tableView = UITableView()
        tableView.register( OrgsCell.self, forCellReuseIdentifier: kOrgsCellId)
        tableView.estimatedRowHeight = 44
        return tableView
    }()
    
    

    @objc func orgInfoUpdated(_ notification: Notification) {
        DispatchQueue.main.async {
            self.organizationsView.reloadData()
        }
        // getting exact cell and updating it would be faster and cleaner
    }


    override  func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.addSubview(organizationsView)
        organizationsView.dataSource = self
        organizationsView.delegate = self
        organizationsView.frame = view.bounds
        
        observer = DataController.shared.fetchOrgs()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("finished!")
            case .failure(let err):
                print(err)
            }
            //
        }, receiveValue: { [weak self] organizations in
            self?.organizations = organizations
            self?.organizationsView.reloadData()
            
            OrgsLogoCache.shared.updateAndStartFetchingMissingLogos(orgs: organizations)
        })
        

        NotificationCenter.default
                          .addObserver(self,
                                       selector: #selector(orgInfoUpdated),
                                       name: NSNotification.Name ("org-details-updated"),
                                       object: nil)
        
        
    }


}

