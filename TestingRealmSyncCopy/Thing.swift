//
//  Thing.swift
//  TestingRealmSyncCopy
//
//  Created by Ivan Schuetz on 09.12.17.
//  Copyright © 2017 Sevenmind. All rights reserved.
//

import UIKit
import RealmSwift

public class Thing: Object {

    @objc public dynamic var uuid: String = ""
    @objc public dynamic var name: String = ""

    public override static func primaryKey() -> String? {
        return "uuid"
    }
}
