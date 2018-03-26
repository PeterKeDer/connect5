//
//  Room.swift
//  Connect5
//
//  Created by Peter Ke on 2017-12-03.
//  Copyright © 2017 PeterKeDer. All rights reserved.
//

import Foundation
import Firebase

// Room, a room for multiplayer, contains two players and a game. Board size will be always 15
class Room {
    var roomId: String // id for easier joining (fir auto id too long)
    var p1Id: String // empty id represents there is still room in this room
    var p2Id: String
    var game: [Int] // move # instead of c: [0,0] -> 0, [0,1] -> 1, [1,1] -> 16 etc
    
    var isFull: Bool {
        return p1Id != "" && p2Id != ""
    }
    
    var currentSide: Int {
        return game.count%2 + 1
    }
    
    init(roomId: String, p1Id: String, p2Id: String, game: [Int]) {
        self.roomId = roomId
        self.p1Id = p1Id
        self.p2Id = p2Id
        self.game = game
    }
    
    convenience init?(snapshot: FIRDataSnapshot) {
        guard
            let roomId = snapshot.childSnapshot(forPath: "roomId").value as? String,
            let p1Id = snapshot.childSnapshot(forPath: "p1Id").value as? String,
            let p2Id = snapshot.childSnapshot(forPath: "p2Id").value as? String else { return nil }
        // game will be set later, if it has game
        self.init(roomId: roomId, p1Id: p1Id, p2Id: p2Id, game: [])
        
        // when there is no moves, game can be nil
        if let game = snapshot.childSnapshot(forPath: "game").value as? [Int] {
            self.game = game
        }
    }
    
    func asDict() -> [String:Any] {
        let dict = ["roomId": roomId,
                    "p1Id": p1Id,
                    "p2Id": p2Id,
                    "game": game] as [String:Any]
        return dict
    }
}
