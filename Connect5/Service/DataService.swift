//
//  DatabaseService.swift
//  Connect5
//
//  Created by Peter Ke on 2017-12-03.
//  Copyright © 2017 PeterKeDer. All rights reserved.
//

import Foundation
import Firebase

let dbBase = FIRDatabase.database().reference() // base reference to database

class DataService {
    static let instance = DataService()
    
    private let refBase = dbBase
    private let refRoom = dbBase.child("rooms")
    
    func createRoom(_ room: Room, completion: @escaping (_ success: Bool, _ message: String?, _ key: String?)->()) {
        let id = room.roomId
        getAllRooms { (rooms, _) in
            guard let rooms = rooms else {
                // unable to get all rooms
                completion(false, "Unable to get rooms. Please check your internet connection and check again later.", nil)
                return
            }
            // check if there is no existing room with same id
            for room in rooms {
                if room.roomId == id {
                    completion(false, "Room with this id already exists. Please choose another id.", nil)
                }
            }
            // creating room
            self.refRoom.childByAutoId().updateChildValues(room.asDict(), withCompletionBlock: { (error, ref) in
                if error != nil {
                    // unable to create room
                    completion(false, "Unable to create room. Please check your internet connection and try again later.", nil)
                    return
                }
                // creation success
                completion(true, nil, ref.key)
            })
        }
    }
    
    func getAllRooms(handler: @escaping (_ rooms: [Room]?, _ keys: [String]?)->()) {
        refRoom.observeSingleEvent(of: .value) { (roomSnapshot) in
            guard let roomSnapshot = roomSnapshot.children.allObjects as? [FIRDataSnapshot] else {
                handler(nil, nil)
                return
            }
            
            var rooms = [Room]()
            var keys = [String]()
            for room in roomSnapshot {
                keys.append(room.key)
                guard let room = Room(snapshot: room) else {
                    handler(nil, nil)
                    return
                }
                rooms.append(room)
            }
            handler(rooms, keys)
        }
    }
    
    // gets room with a given key. Will be nil if not found
    func getRoom(key: String, handler: @escaping (_ room: Room?, _ message: String?)->()) {
        refRoom.child(key).observeSingleEvent(of: .value) { (snapshot) in
            guard let room = Room(snapshot: snapshot) else {
                handler(nil, "Unable to get room. Please check the id and try again later.")
                return
            }
            handler(room, nil)
        }
    }
    
    // get room with room id. Needs to check through all rooms.
    // This should only be called once (when first joining room), other calls should be called with key
    func getRoom(roomId: String, handler: @escaping (_ room: Room?, _ message: String?, _ key: String?)->()) {
        refRoom.observeSingleEvent(of: .value) { (roomSnapshot) in
            guard let roomSnapshot = roomSnapshot.children.allObjects as? [FIRDataSnapshot] else {
                handler(nil, "Unable to get room. Please check your internet connection and try again later.", nil)
                return
            }
            
            for snapshot in roomSnapshot {
                guard let room = Room(snapshot: snapshot) else {
                    handler(nil, "Unable to get room. Please try again later.", nil)
                    return
                }
                // compare room id
                if room.roomId == roomId {
                    // found room
                    handler(room, nil, snapshot.ref.key)
                    return
                }
            }
            
            // cannot find room with id
            handler(nil, "Room with id \(roomId) does not exist. Please try again later.", nil)
            
        }
    }
    
    // NOTE: since presence system is too complicated for rooms system, before a user joins a new room, it will clear all other rooms with the user's uid as p1/p2Id if that room is empty, or remove the user's id if someone's still in it
    // where this func is used
    func deleteAllRoomsByUser(id: String, completion: @escaping ()->()) {
        getAllRooms { (rooms, keys) in
            guard let rooms = rooms, let keys = keys else {
                completion()
                return
            }
            var roomKeysAndDeleteType = [String:Int]() // int: 0 - delete, 1 - delete p1Id, 2 - delete p2Id
            for i in 0..<rooms.count {
                // changed user's id to "". If it's emtpy after, delete it
                if rooms[i].p1Id == id || rooms[i].p2Id == id {
                    if rooms[i].isFull {
                        if rooms[i].p1Id == id {
                            roomKeysAndDeleteType[keys[i]] = 1
                        } else {
                            roomKeysAndDeleteType[keys[i]] = 2
                        }
                    } else {
                        // room not full - will be deleted
                        roomKeysAndDeleteType[keys[i]] = 0
                    }
                }
            }
            if roomKeysAndDeleteType.count > 0 {
                var count = 0
                for (key, type) in roomKeysAndDeleteType {
                    let c = count == roomKeysAndDeleteType.count-1 ? completion : nil
                    if type == 0 {
                        self.deleteRoom(key: key, completion: c)
                    } else {
                        self.refRoom.child(key).child("p\(type)Id").setValue("", withCompletionBlock: { (_, _) in
                            if let c = c {
                                c()
                            }
                        })
                    }
                    count += 1
                }
            } else {
                completion()
            }
        }
    }
    
    func deleteRoom(key: String, completion: (()->())?) {
        refRoom.child(key).removeValue { (_, _) in
            if let completion = completion {
                completion()
            }
        }
    }
    
    // game functions
    // attempts to join room. Set isFull, p1/p2Id
    func getAndJoinRoom(_ roomId: String, completion: @escaping (_ room: Room?, _ message: String?, _ key: String?, _ move: Int)->()) {
        
        deleteAllRoomsByUser(id: AuthService.instance.id) {
            self.getRoom(roomId: roomId, handler: { (room, message, key) in
                guard let room = room, let key = key else {
                    completion(nil, message, nil, 0)
                    return
                }
                // got room, now join
                if room.isFull {
                    completion(nil, "Room is already full. Please try again later.", nil, 0)
                    return
                }
                let userId = AuthService.instance.id as NSString
                let moveToJoin = room.p1Id == "" ? 1 : 2
                let ref = self.refRoom.child(key)
                ref.child("p\(moveToJoin)Id").setValue(userId) { (error, _) in
                    if error == nil {
                        // since another joined, room will be full, so set isFull value
                        ref.child("isFull").setValue(true, withCompletionBlock: { (error, _) in
                            if error == nil {
                                // no error - joins successfully
                                completion(room, nil, key, moveToJoin)
                            } else {
                                completion(nil, "Unable to join. Please try again later.", nil, 0)
                            }
                        })
                    } else {
                        completion(nil, "Unable to join. Please try again later.", nil, 0)
                    }
                }
            })
        }
        
    }
    
    
    func joinRoom(_ room: Room, key: String, completion: @escaping (_ success: Bool, _ message: String?, _ move: Int)->()) {
        // delete all other rooms with user before joining
        deleteAllRoomsByUser(id: AuthService.instance.id) {
            let ref = self.refRoom.child(key)
            
            // check if room is full
            if room.isFull {
                completion(false, "Room is already full. Please try again later.", 0)
                return
            }
            let userId = AuthService.instance.id as NSString
            let moveToJoin = room.p1Id == "" ? 1 : 2
            ref.child("p\(moveToJoin)Id").setValue(userId) { (error, _) in
                if error == nil {
                    ref.child("isFull").setValue(true, withCompletionBlock: { (error, _) in
                        if error == nil {
                            completion(true, nil, moveToJoin)
                        } else {
                            completion(false, "Unable to join. Please try again later.", 0)
                        }
                    })
                } else {
                    completion(false, "Unable to join. Please try again later.", 0)
                }
            }
        }
    }
    
    // used when creating room, then joining as a side
    func createAndJoinRoom(id: String, completion: @escaping (_ room: Room?, _ message: String?, _ key: String?)->()) {
        // delete all other rooms with user before creating
        deleteAllRoomsByUser(id: AuthService.instance.id) {
        
            let room = Room(roomId: id, p1Id: AuthService.instance.id, p2Id: "", game: [])
            self.createRoom(room) { (success, message, key) in
                if success {
                    completion(room, nil, key)
                } else {
                    completion(nil, message, nil)
                }
            }
        }
    }
    
    func updateGame(key: String, game: [Int], completion: @escaping (_ message: String?)->()) {
        refRoom.child(key).child("game").setValue(game) { (error, _) in
            if error != nil {
                completion("Unable to upload move. Please check your internet connection and try again.")
                return
            }
            completion(nil)
        }
    }
    
    func restartGame(key: String, completion: @escaping (_ message: String?)->()) {
        refRoom.child(key).child("game").setValue([]) { (error, _) in
            if error != nil {
                completion("Unable to restart game. Please check your internet connection and try again.")
                return
            }
            completion(nil)
        }
    }
    
    // handler will be called when initially called or when room updates
    func startObservingRoom(key: String, handler: @escaping (_ snapshot: FIRDataSnapshot)->()) {
        refRoom.child(key).observe(.value) { (snapshot) in
            handler(snapshot)
        }
    }
    
    func stopObservingRoom(key: String) {
        refRoom.child(key).removeAllObservers()
    }
    
    // check if is connected to internet/Firebase
    func isConnected(handler: @escaping (_ isConnected: Bool)->()) {
        let connectedRef = FIRDatabase.database().reference(withPath: ".info/connected")
        connectedRef.observeSingleEvent(of: .value, with: { snapshot in
            if let connected = snapshot.value as? Bool, connected {
                handler(true)
            } else {
                handler(false)
            }
        })
    }
    
}
