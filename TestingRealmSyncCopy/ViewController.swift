//
//  ViewController.swift
//  TestingRealmSyncCopy
//
//  Created by Ivan Schuetz on 09.12.17.
//  Copyright © 2017 Sevenmind. All rights reserved.
//

import UIKit
import RealmSwift
import Realm.Dynamic

class ViewController: UIViewController {

    let syncAuthURL = URL(string: "http://127.0.0.1:9080")!
    let syncServerURL = URL(string: "realm://127.0.0.1:9080/~/copytest")!

    var localRealmUrl: URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        return documentsDir.appendingPathComponent("default.realm")
    }

    var config = Realm.Configuration(
        schemaVersion: 1,
        migrationBlock: { migration, oldSchemaVersion in }
    )

    var localConfig: Realm.Configuration {
        var config = self.config
        config.fileURL = localRealmUrl
        return config
    }

    var localConfigRLM: RLMRealmConfiguration {
        let configuration = RLMRealmConfiguration()
        configuration.schemaVersion = 1
        configuration.fileURL = localRealmUrl
//        configuration.dynamic = true
        //configuration.readOnly = true
        return configuration
    }

    func syncedConfig(user: SyncUser) -> Realm.Configuration {
        var config = self.config
        config.syncConfiguration = SyncConfiguration(user: user, realmURL: syncServerURL)
        config.objectTypes = [Thing.self]
        return config
    }

    func createLocalRealm() throws -> Realm {
        return try Realm(configuration: localConfig)
    }

    func storeSomething() {
        let thing = Thing()
        thing.uuid = "0"
        thing.name = "Thing"

        let realm = try! createLocalRealm()
        try! realm.write {
            realm.add(thing, update: true)
        }
    }

    var things: Results<Thing>!

    override func viewDidLoad() {
        super.viewDidLoad()
        print("local realm path: \(localRealmUrl)")

        things = try! createLocalRealm().objects(Thing.self)
    }

    func login(isRegister: Bool) {
        let credentials = SyncCredentials.usernamePassword(username: "test@test.com", password: "test123", register: isRegister)
        SyncUser.logIn(with: credentials, server: syncAuthURL) { user, error in

            DispatchQueue.main.async {

                if let user = user {
                    print("Logged in. User: \(user)")

                    Realm.Configuration.defaultConfiguration = self.syncedConfig(user: user)

                    self.copyLocalToSyncRealm(user: user) {
                        print("Success!!")
                    }

                } else {
                    print("Error during login/register, no user: \(String(describing: error))")
               }
            }
        }
    }

    func copyLocalToSyncRealm(user: RLMSyncUser, onFinish: @escaping () -> Void) {
        print("Start copying local realm to synced realm")

        let localConfig = localConfigRLM

        print("Path of local realm: \(String(describing: localConfig.fileURL))")

        RLMRealm.asyncOpen(with: localConfig, callbackQueue: .main) { realm, error in
            if let realm = realm {
                self.copyToSyncRealmWithRealm(localRlmRealm: realm, user: user)
                print("Finished copying local realm to synced realm")
                onFinish()
            } else {
                print("Error opening realm: \(String(describing: error))")
                onFinish()
            }
        }
    }

    func copyToSyncRealmWithRealm(localRlmRealm: RLMRealm, user: RLMSyncUser) {
        let syncConfig = RLMRealmConfiguration()
        syncConfig.syncConfiguration = RLMSyncConfiguration(user: user, realmURL: syncServerURL)
        syncConfig.customSchema = localRlmRealm.schema

        let syncRealm = try! RLMRealm(configuration: syncConfig)
        syncRealm.schema = syncConfig.customSchema!
        try! syncRealm.transaction {
            let objectSchema = syncConfig.customSchema!.objectSchema
            for schema in objectSchema {
                let allObjects = localRlmRealm.allObjects(schema.className)
                for i in 0..<allObjects.count {
                    let object = allObjects[i]
                    RLMCreateObjectInRealmWithValue(syncRealm, schema.className, object, true)
                }
            }
        }
    }
    @IBAction func didTapLogin(_ sender: Any) {
        login(isRegister: false)
    }

    @IBAction func didTapRegister(_ sender: Any) {
        login(isRegister: true)
    }

    @IBAction func didTapStoreSomething(_ sender: Any) {
        storeSomething()
    }
}

