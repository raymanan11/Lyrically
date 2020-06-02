//
//  TokenManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/29/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper

struct TokenManager {
    
    let tokenSwap = "https://tangible-lean-level.glitch.me/api/token"
    let refresh = "https://tangible-lean-level.glitch.me/api/refresh_token"
    
    var dispatchGroup = DispatchGroup()
    
    func getAccessToken(spotifyCode: String) {
        let parameters = ["code": spotifyCode]
        AF.request(tokenSwap, method: .post, parameters: parameters).responseJSON(completionHandler: {
            response in
//            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
//                print("Data: \(utf8Text)")
//            }
            if let result = response.value {
                let jsonData = result as! NSDictionary
                let accessToken = jsonData.value(forKey: "access_token") as? String
                let refreshToken = jsonData.value(forKey: "refresh_token") as? String

                let _: Bool = KeychainWrapper.standard.set(accessToken!, forKey: "accessToken")
                let _: Bool = KeychainWrapper.standard.set(refreshToken!, forKey: "refreshToken")

            }
        })
    }
    
    func refreshToken() {
        print("In refresh token")
        let refresh = "https://tangible-lean-level.glitch.me/api/refresh_token"
        let refreshToken: String? = KeychainWrapper.standard.string(forKey: Constants.refreshToken)
        let parameters = ["refresh_token" : refreshToken]
        dispatchGroup.enter()
        AF.request(refresh, method: .post, parameters: parameters).responseJSON(completionHandler: {
            response in

            if let result = response.value {
                print("Handling refresh token request")
                let jsonData = result as! NSDictionary
                let accessToken = jsonData.value(forKey: "access_token") as? String

                let _: Bool = KeychainWrapper.standard.set(accessToken ?? "", forKey: Constants.accessToken)
                print("Got the new access token!")
                //print(accessTokens ?? "none")
                self.dispatchGroup.leave()
            }
        })
        dispatchGroup.notify(queue: .main) {
            NotificationCenter.default.post(name: NSNotification.Name(Constants.newAccessToken), object: nil)
        }
    }
}

