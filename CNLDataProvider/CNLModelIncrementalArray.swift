//
//  CNLModelIncrementalArray.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 02/03/2017.
//  Copyright © 2017 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

public protocol CNLModelIncrementalArrayElementStates: CNLModelObject, CNLModelDictionary {
    //func setDefaultState()
}

public protocol CNLModelIncrementalArrayElement: CNLModelObjectPrimaryKey {
    var states: CNLModelIncrementalArrayElementStates { get set }
}

public protocol CNLModelIncrementalArray: class, CNLDataSourceModel {
    associatedtype ArrayElement: CNLModelIncrementalArrayElement, CNLModelDictionary

    var list: [ArrayElement] { get set }
    
    var lastTimestamp: Date? { get set }
    var statesLastTimestamp: Date? { get set }
    
    func reset()
    func createItems(_ data: CNLDictionary) -> [ArrayElement]?
    func loadFromDictionary(_ data: CNLDictionary) -> [ArrayElement]
    func storeToDictionary() -> CNLDictionary
    func afterLoad()
    func preprocessData(_ data: CNLDictionary?) -> CNLDictionary?
    func indexOf(item: ArrayElement) -> Int?
    init()

    // states
    func createStatesAPI() -> CNLModelAPI?
    func updateStates(success: @escaping CNLModelCompletion, failed: @escaping CNLModelFailed)
    func updateStatesFromDictionary(_ data: CNLDictionary)
    
    func createdItems(_ data: CNLDictionary?) -> [ArrayElement]?
    func modifiedItems(_ data: CNLDictionary?) -> [ArrayElement]?
    func deletedItems(_ data: CNLDictionary?) -> [ArrayElement.KeyType]?
}

fileprivate var incrementalArrayLastTimestampKey: String = "incrementalArrayLastTimestampKey"
fileprivate var incrementalArrayStatesLastTimestampKey: String = "incrementalArrayStatesLastTimestampKey"

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

    public final var statesLastTimestamp: Date? {
        get {
            if let value = (objc_getAssociatedObject(self, &incrementalArrayStatesLastTimestampKey) as? CNLAssociated<Date?>)?.closure {
                return value
            } else {
                return nil
            }
        }
        set {
            objc_setAssociatedObject(self, &incrementalArrayStatesLastTimestampKey, CNLAssociated<Date?>(closure: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
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

    public func loadFromDictionary(_ data: CNLDictionary) -> [ArrayElement] {
        lastTimestamp = data.date("timestamp") ?? lastTimestamp
        if let itemsInfo = data["items"] as? CNLArray {
            return defaultLoadFrom(itemsInfo)
        }
        return []
    }

    public func storeToDictionary() -> CNLDictionary {
        let items = list.map { $0.storeToDictionary() }
        var result: CNLDictionary = ["items": items]
        result["timestamp"] = lastTimestamp?.timeIntervalSince1970
        return result
    }
    
    public func indexOf(item: ArrayElement) -> Int? {
        return self.list.index { return $0.primaryKey == item.primaryKey }
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
                            
                            modified.forEach { modifiedItem in
                                if let index = self.indexOf(item: modifiedItem) {
                                    modifiedItem.states = self.list[index].states
                                    self.list[index] = modifiedItem
                                    return
                                }
                                self.list.append(modifiedItem)
                            }
                            
                        }
                        if let deleted = self.deletedItems(data) {
                            #if DEBUG
                                CNLLog("Model removed items: \(deleted.count)", level: .debug)
                            #endif
                            
                            self.list = self.list.filter { item in !deleted.contains(item.primaryKey) }
                        }
                    }
                    if let timestamp = apiObject.answerJSON?.date("timestamp") {
                        self.lastTimestamp = timestamp
                    }

                    self.updateStates(
                        success: { model, status in
                            self.afterLoad()
                            #if DEBUG
                                CNLLog("Model count: \(self.list.count)", level: .debug)
                            #endif
                            success(model, status)
                        },
                        failed: { apiObject, error in failed(self, error) }
                    )
                },
                fail: { apiObject in failed(self, apiObject.errorStatus) },
                networkError: { apiObject, error in failed(self, apiObject.errorStatus(error)) }
            )
        } else {
            success(self, okStatus) //(kind: CNLErrorKind.Ok, success: true))
        }
    }

    public func updateStates(success: @escaping CNLModelCompletion, failed: @escaping CNLModelFailed) {
        if let statesAPI = createStatesAPI() {
            CNLModelNetworkProvider?.performRequest(
                api: statesAPI,
                success: { apiObject in
                    if let statesInfo = apiObject.answerJSON {
                        self.updateStatesFromDictionary(statesInfo)
                    }
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

    public init?(data: CNLDictionary?) {
        guard let data = data else { return nil }
        self.init()
        list = loadFromDictionary(data)
    }
    
}
