//
//  ApiHandler.swift
//  GithubFetch
//
//  Created by Anton Tugolukov on 4/3/23.
//
import Combine
import Foundation



class DataController {
    static let shared = DataController()
    
    func fetchOrgs() -> Future<[OrgInfo], Error> {
        let future: Future<[OrgInfo], Error> = Future { [weak self] promise in
            if let orgs = DataStore.persistedOrgs() {
                promise(.success(orgs))
                self?.startFetchingDetails()
                return
            }
            
            guard let url = URL(string: "https://api.github.com/organizations") else { fatalError() }
            if let strongSelf = self {
                strongSelf.fetchAndDecode(url: url, type: [OrgInfo].self) { orgs, err in
                    if let orgs = orgs {
                        DataStore.persistOrgs(orgs)
                        promise(.success(orgs))
                        strongSelf.startFetchingDetails()
                    }
                    else {
                        //TODO: treat no orgs as err?
                    }
                }
            }
        }
        return future
    }
    
    private func fetchAndDecode<T>(url: URL, type: T.Type, completion: @escaping (T?, Error?) -> ()) -> Void where T : Decodable {
        let request = URLRequest(url: url)
        
        URLRequestHandler.handle(request) {[weak self] data, response, error in
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "remote api error", code: 12, userInfo: ["description" : "No data for url:\(url)"]))
                return
            }
            print(String(data: data, encoding: .utf8))
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let val = try decoder.decode(type, from: data)
                completion(val, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    private func fetchOrgDetails(org:OrgInfo) -> Void {
        guard let detailsUrl = URL(string:org.url) else {
            print("Err. Bad org url")
            return
        }
        
        fetchAndDecode(url: detailsUrl, type: OrgDetailedInfo.self) { [weak self] orgDetails, error in
            if let orgDetails = orgDetails {
                DataStore.saveOrgDetails(org:  org, details: orgDetails)
                
                //
                NotificationCenter.default
                    .post(name:NSNotification.Name("org-details-updated"), object: nil, userInfo: nil)
            }
            else {
                print("Err. Failed fetching org details")
            }
        }
    }
    

    
    private func startFetchingDetails() {
        if let orgs = DataStore.persistedOrgs() {
            for org in orgs {
                if DataStore.persistedDetails(orgLogin: org.login) == nil {
                    fetchOrgDetails(org: org)
                }
            }
        }
    }
}
