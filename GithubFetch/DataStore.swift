//
//  DataStore.swift
//  GithubFetch
//
//  Created by Anton Tugolukov on 4/5/23.
//

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

class DataStore {
    static let shared = DataStore()
    
    static func saveOrgDetails(org: OrgInfo, details:OrgDetailedInfo) {
        let encoder = JSONEncoder()
        
        UserDefaults.standard.set(try? encoder.encode(details), forKey: org.login)
        UserDefaults.standard.synchronize()
    }
  
    static func persistedOrgs() -> [OrgInfo]? {
        if let data = UserDefaults.standard.object(forKey: "orgs_from_github") as? Data {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try? decoder.decode([OrgInfo].self, from: data)
        }
        return nil
    }
    
    static func persistOrgs(_ orgs: [OrgInfo]) {
        let encoder = JSONEncoder()
        
        if let data = try? encoder.encode(orgs) {
            UserDefaults.standard.set(data, forKey: "orgs_from_github")
            UserDefaults.standard.synchronize()
        }
    }
    
    static func persistedDetails(orgLogin: String) -> OrgDetailedInfo? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        if let data = UserDefaults.standard.object(forKey: orgLogin) as? Data {
            return try? decoder.decode(OrgDetailedInfo.self, from: data)
        }
        
        return nil
    }
}
