//
//  NextcloudAVAssetResourceLoaderDelegate.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 17/2/24.
//

import AVFoundation

class NextcloudAVAssetResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    let user: String
    let password: String

    init(user: String, password: String) {
        self.user = user
        self.password = password
        super.init()
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForResponseTo authenticationChallenge: URLAuthenticationChallenge
    ) -> Bool {
        let authMethod = authenticationChallenge.protectionSpace.authenticationMethod
        guard authMethod == NSURLAuthenticationMethodHTTPBasic else {
            return false
        }

        let credential = URLCredential(user: user, password: password, persistence: .forSession)
        authenticationChallenge.sender?.use(credential, for: authenticationChallenge)
        return true
    }
}
