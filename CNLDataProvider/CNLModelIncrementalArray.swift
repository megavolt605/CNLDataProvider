//
//  CNLModelIncrementalArray.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 02/03/2017.
//  Copyright © 2017 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

public protocol CNLModelIncrementalArray: class, CNLDataSourceModel {
    associatedtype ArrayElement: CNLModelObjectPrimaryKey, CNLModelDictionary

    var list: [ArrayElement] { get set }
    var lastTimestamp: Date? { get set }
    func reset()
    func createItems(_ data: CNLDictionary) -> [ArrayElement]?
    static func loadFromArray(_ array: CNLArray?) -> Self?
    func loadFromArray(_ array: CNLArray) -> [ArrayElement]
    func storeToArray() -> CNLArray
    func afterLoad()
    func preprocessData(_ data: CNLDictionary?) -> CNLDictionary?
    init()

    func createdItems(_ data: CNLDictionary?) -> [ArrayElement]?
    func modifiedItems(_ data: CNLDictionary?) -> [ArrayElement]?
    func deletedItems(_ data: CNLDictionary?) -> [ArrayElement.KeyType]?
}

fileprivate var incrementalArrayLastTimestampKey: String = "incrementalArrayLastTimestampKey"

public extension CNLModelObject where Self: CNLModelIncrementalArray {
    
    public var isPagingEnabled: Bool { return false }

    public final var lastTimestamp: Date? {
        get {
            if let value = (objc_getAssociatedObject(self, &incrementalArrayLastTimestampKey) as? CNLAssociated<Date?>)?.closure {
                return value
            } else {
                return nil
            }
        }
        set {
            objc_setAssociatedObject(self, &incrementalArrayLastTimestampKey, CNLAssociated<Date?>(closure: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
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
    
    public func update(success: @escaping CNLModelCompletion, failed: @escaping CNLModelFailed) {
        if let localAPI = createAPI() {
            CNLModelNetworkProvider?.performRequest(
                api: localAPI,
                success: { apiObject in
                    if let data = self.preprocessData(apiObject.answerJSON) {
                        if let created = self.createdItems(data) {
                            #if DEBUG
                                CNLLog("Model new items: \(created.count)", level: .debug)
                            #endif
                            
                            self.list += created
                        }
                        if let modified = self.modifiedItems(data) {
                            #if DEBUG
                                CNLLog("Model changed items: \(modified.count)", level: .debug)
                            #endif
                            
                            let ids = modified.map { item in return item.primaryKey }
                            self.list = self.list.filter { item in !ids.contains(item.primaryKey) }
                            self.list += modified
                        }
                        if let deleted = self.deletedItems(data) {
                            #if DEBUG
                                CNLLog("Model removed items: \(deleted.count)", level: .debug)
                            #endif
                            
                            self.list = self.list.filter { item in !deleted.contains(item.primaryKey) }
                        }
                    }
                    self.afterLoad()
                    #if DEBUG
                        CNLLog("Model count: \(self.list.count)", level: .debug)
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

    public func afterLoad() { }
    
    public func defaultLoadFrom(_ array: CNLArray) -> [ArrayElement] {
        let newListOfList = array.mapSkipNil { return self.createItems($0) }
        let newList = newListOfList.flatMap { return $0 }
        return newList
    }
    
    private func loadItems(_ data: CNLDictionary?, section: String) -> [ArrayElement]? {
        guard let itemsData = data?[section] as? CNLArray else { return nil }
        return defaultLoadFrom(itemsData)
    }
    
    public func createdItems(_ data: CNLDictionary?) -> [ArrayElement]? {
        return loadItems(data, section: "created")
    }
    
    public func modifiedItems(_ data: CNLDictionary?) -> [ArrayElement]? {
        return loadItems(data, section: "modified")
    }
    
    public func deletedItems(_ data: CNLDictionary?) -> [ArrayElement.KeyType]? {
        return data?["deleted"] as? [ArrayElement.KeyType]
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
