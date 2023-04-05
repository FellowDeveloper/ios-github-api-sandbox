//
//  PicCache.swift
//  GithubFetch
//
//  Created by Anton Tugolukov on 4/4/23.
//

import Foundation
import UIKit

class OrgsLogoCache {
    
    static let shared = OrgsLogoCache()
    
    
    
    private var cachedPics: [String:UIImage] = [:]
    
    // Public api
    
    func cachedLogoForOrg(org: OrgInfo) -> UIImage? {
        return cachedPics[logoFiliName(org)]
    }
    
    private func logoFiliName(_ org: OrgInfo) -> String {
        let logoFileName = "logo-\(org.login).pic"
        return logoFileName
    }
    private func cachedLogoFileUrl(_ org: OrgInfo) -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDir = urls[0]
        return documentsDir.appendingPathComponent(logoFiliName(org))
    }
    
    private func orgsWithNoLogo(orgs: [OrgInfo]) -> [OrgInfo] {
        return orgs.filter {!FileManager.default.fileExists(atPath:cachedLogoFileUrl($0).path) }
    }
    
    private func loadCachedImages(orgs: [OrgInfo]) {
        for org in orgs {
            if let img = cachedLogoForOrg(org: org) {
                continue
            }
            
            let picName = logoFiliName(org)
            if let image = UIImage(contentsOfFile: cachedLogoFileUrl(org).path) {
                cachedPics[picName] = image
            }
        }
    }
    
    public func updateAndStartFetchingMissingLogos(orgs: [OrgInfo]) {
        loadCachedImages(orgs: orgs)
        
        let noLogoOrgs = orgsWithNoLogo(orgs: orgs)
        
        for org in noLogoOrgs {
            downloadLogoImage(org: org)
        }
        
    }
    
    private func downloadLogoImage(org: OrgInfo) -> Void {
        guard let url = URL(string: org.avatarUrl) else {
            // TODO: ERR!
            return
        }
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            
            guard let strongSelf = self else { return }
                
            if let error = error {
                // TODO: ERR!
                return
            }
            
            guard let data = data else {
                // TODO: ERR!
                return
            }
            
            if let image = UIImage(data: data) {
                strongSelf.cachedPics[strongSelf.logoFiliName(org)] = image
                try! data.write(to: strongSelf.cachedLogoFileUrl(org))
                NotificationCenter.default
                    .post(name:NSNotification.Name("org-details-updated"), object: nil, userInfo: nil)
            }
        }.resume()
    }
}
