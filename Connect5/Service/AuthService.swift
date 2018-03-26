//
//  AuthService.swift
//  Connect5
//
//  Created by Peter Ke on 2017-12-03.
//  Copyright © 2017 PeterKeDer. All rights reserved.
//

import Foundation
import Firebase

class AuthService {
    static let instance = AuthService()
    
    var id: String {
        return (FIRAuth.auth()?.currentUser?.uid)!
    }
    
    var isLoggedOn: Bool {
        return FIRAuth.auth()?.currentUser != nil
    }
    
    func logIn(completion: @escaping (_ success: Bool)->()) {
        FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
            if error != nil {
                // has some error
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    func logOut(completion: (_ success: Bool)->()) {
        do {
            try FIRAuth.auth()?.signOut()
            completion(true)
        } catch {
            print(error)
            completion(false)
        }
    }
}
