//
//  CNLModelIncrementalArray.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 02/03/2017.
//  Copyright © 2017 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

private var incrementalArrayAdditionalRecords = "additionalRecords"

public protocol CNLModelIncrementalArray: class, CNLDataSourceModel {
    associatedtype ArrayElement: CNLModelDictionary, CNLModelObjectPrimaryKey

    var list: [ArrayElement] { get set }
    var lastTimestamp: Date? { get set }
    
    func reset()
    func createItems(_ data: CNLDictionary) -> [ArrayElement]?
    func loadFromArray(_ array: CNLArray) -> [ArrayElement]
    func storeToArray() -> CNLArray
    func updateArray()
    func updateArray(success: @escaping CNLModelCompletion, failed: @escaping CNLModelFailed)
    func afterLoad()
    func preprocessData(_ data: CNLDictionary?) -> CNLDictionary?
    init()

    func createdItems(_ data: CNLDictionary) -> [ArrayElement]?
    func modifiedItems(_ data: CNLDictionary) -> [ArrayElement]?
    func deletedItems(_ data: [ArrayElement.KeyType]) -> [ArrayElement.KeyType]?
}

public extension CNLModelObjectPrimaryKey where Self: CNLModelIncrementalArray, KeyType == Self.ArrayElement.KeyType {
    
    public func reset() {
        list = []
    }
    
    public func createItems(_ data: CNLDictionary) -> [ArrayElement]? {
        if let item = ArrayElement(dictionary: data) {
            return [item]
        }
        return nil
    }
    
    public func preprocessData(_ data: CNLDictionary?) -> CNLDictionary? {
        return data
    }

    public func loadFromArray(_ array: CNLArray) -> [ArrayElement] {
        return defaultLoadFrom(array)
    }

    public func storeToArray() -> CNLArray {
        let captureList = list
        return captureList.map { $0.storeToDictionary() }
    }
    
    public static func loadFromArray(_ array: CNLArray?) -> Self? {
        guard let array = array else { return nil }
        let result = Self()
        result.list = result.loadFromArray(array)
        return result
    }
    
    public func updateArray() {
        updateArray(success: { _, _ in }, failed: { _, _ in })
    }

    public func updateArray(success: @escaping CNLModelCompletion, failed: @escaping CNLModelFailed) {
        if let localAPI = createAPI() {
            CNLModelNetworkProvider?.performRequest(
                api: localAPI,
                success: { apiObject in
                    if let data = self.preprocessData(apiObject.answerJSON) {
                        if let created = self.createdItems(data) {
                            #if DEBUG
                            print("Model new items: \(created.count)")
                            #endif
                            self.list += created
                        }
                        if let modified = self.modifiedItems(data["modified"] as? CNLDictionary) {
                            #if DEBUG
                            print("Model changed items: \(modified.count)")
                            #endif
                            let ids = modified.map { item in return item.primaryKey }
                            self.list = self.list.filter { item in !ids.contains(item.primaryKey) }
                            self.list += modified
                        }
                        if let deleted = self.deletedItems(data["deleted"] as? [ArrayElement.KeyType]) {
                            #if DEBUG
                            print("Model removed items: \(deleted.count)")
                            #endif
                            self.list = self.list.filter { item in !deleted.contains(item.primaryKey) }
                        }
                    }
                    #if DEBUG
                    print("Model count: \(self.list.count)")
                    #endif
                    success(self, apiObject.status)
                },
                fail: { apiObject in failed(self, apiObject.errorStatus) },
                networkError: { apiObject, error in failed(self, apiObject.errorStatus(error)) }
            )
        } else {
            success(self, okStatus) //(kind: CNLErrorKind.Ok, success: true))
        }
    }

    public func defaultLoadFrom(_ array: CNLArray) -> [ArrayElement] {
        let newListOfList = array.mapSkipNil { return self.createItems($0) }
        let newList = newListOfList.flatMap { return $0 }
        return newList
    }
    
    func createdItems(_ data: CNLDictionary?) -> [ArrayElement]? {
        guard let itemsData = data?["created"] as? CNLArray else { return nil }
        return defaultLoadFrom(itemsData)
    }
    
    func modifiedItems(_ data: CNLDictionary?) -> [ArrayElement]? {
        guard let itemsData = data?["modified"] as? CNLArray else { return nil }
        return defaultLoadFrom(itemsData)
    }
    
    func deletedItems(_ data: [ArrayElement.KeyType]?) -> [ArrayElement.KeyType]? {
        return data
    }

    public init?(array: CNLArray?) {
        self.init()
        if let data = array {
            list = loadFromArray(data)
        } else {
            return nil
        }
    }
    
}
