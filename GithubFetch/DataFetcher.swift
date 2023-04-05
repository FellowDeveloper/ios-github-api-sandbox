//
//  ApiHandler.swift
//  GithubFetch
//
//  Created by Anton Tugolukov on 4/3/23.
//
import Combine
import Foundation

class OrgDetailedInfo: Codable {
    var htmlUrl: String
    var name: String
}


class OrgInfo: Codable {
    var login: String
    var id: Int
    var url: String
    var avatarUrl: String
    var description: String?
    var detailedInfo: OrgDetailedInfo?
}

class DataFetcher {
    static let shared = DataFetcher()
    
    
    private func saveOrgDetails(org: OrgInfo, details:OrgDetailedInfo) {
        let encoder = JSONEncoder()
        
        UserDefaults.standard.set(try? encoder.encode(details), forKey: org.login)
        UserDefaults.standard.synchronize()
        
        NotificationCenter.default
            .post(name:NSNotification.Name("org-details-updated"), object: nil, userInfo: nil)
    }
    
    private func fetchAndDecode<T>(url: URL, type: T.Type, completion: @escaping (T?, Error?) -> ()) -> Void where T : Decodable {
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
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
        }.resume()
    }
    
    func fetchOrgDetails(org:OrgInfo) -> Void {
        guard let detailsUrl = URL(string:org.url) else {
            // TODO: ERR!
            return
        }
        
        fetchAndDecode(url: detailsUrl, type: OrgDetailedInfo.self) { [weak self] orgDetails, error in
            if let orgDetails = orgDetails {
                self?.saveOrgDetails(org:  org, details: orgDetails)
            }
            else {
                //TODO: treat no org detail as err?
            }
        }
    }
    
    func fetchOrgs() -> Future<[OrgInfo], Error> {
        let future: Future<[OrgInfo], Error> = Future { [weak self] promise in
            if let orgs = self?.persistedOrgs() {
                promise(.success(orgs))
                self?.startFetchingDetails()
                return
            }
            
            guard let url = URL(string: "https://api.github.com/organizations") else { fatalError() }
            if let strongSelf = self {
                strongSelf.fetchAndDecode(url: url, type: [OrgInfo].self) { orgs, err in
                    if let orgs = orgs {
                        strongSelf.persistOrgs(orgs)
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
    
    func persistedOrgs() -> [OrgInfo]? {
        if let data = UserDefaults.standard.object(forKey: "orgs_from_github") as? Data {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try? decoder.decode([OrgInfo].self, from: data)
        }
        return nil
    }
    
    func persistOrgs(_ orgs: [OrgInfo]) {
        let encoder = JSONEncoder()
        
        if let data = try? encoder.encode(orgs) {
            UserDefaults.standard.set(data, forKey: "orgs_from_github")
            UserDefaults.standard.synchronize()
        }
    }
    
    func persistedDetails(orgLogin: String) -> OrgDetailedInfo? {
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        if let data = UserDefaults.standard.object(forKey: orgLogin) as? Data {
            return try? decoder.decode(OrgDetailedInfo.self, from: data)
        }
        
        return nil
    }
    
    func startFetchingDetails() {
        if let orgs = persistedOrgs() {
            for org in orgs {
                if persistedDetails(orgLogin: org.login) == nil {
                    fetchOrgDetails(org: org)
                }
            }
        }
    }
}
