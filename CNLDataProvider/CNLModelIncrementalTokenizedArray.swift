//
//  CNLModelIncrementalTokenizedArray.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 19/04/2017.
//  Copyright © 2017 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

public typealias CNLModelObjectToken = String

public protocol CNLModelIncrementalTokenizedArray: CNLModelIncrementalArray {
    associatedtype ArrayElement: CNLModelObjectTokenized, CNLModelDictionary
    
    var tokens: [String] { get set }
    func reset()
    func createItems(_ data: CNLDictionary, withToken token: CNLModelObjectToken) -> [ArrayElement]?
    
    //static func loadFromDictionary(_ data: CNLDictionary?) -> [CNLModelObjectToken: ArrayElement]?
    func loadFromDictionary(_ data: CNLDictionary) -> [ArrayElement]
    func storeToDictionary() -> CNLDictionary
    
    // states
    func updateStatesFromDictionary(_ data: CNLDictionary, forItemKey itemKey: ArrayElement.KeyType, withToken token: CNLModelObjectToken)
    func updateStatesFromDictionary(_ data: CNLDictionary, forItem item: ArrayElement)
    
}

public protocol CNLModelObjectTokenized: CNLModelObject, CNLModelIncrementalArrayElement {
    var token: CNLModelObjectToken { get set }
}

public extension CNLModelObject where Self: CNLModelIncrementalTokenizedArray, Self.ArrayElement: CNLModelObjectTokenized {
    
    public func reset() {
        list = []
    }
    
    public func createItems(_ data: CNLDictionary, withToken token: CNLModelObjectToken) -> [ArrayElement]? {
        if let item = ArrayElement(dictionary: data) {
            item.token = token
            return [item]
        }
        return nil
    }

    public func defaultLoadFrom(_ array: CNLArray, withToken token: String) -> [ArrayElement] {
        let newListOfList = array.mapSkipNil { return self.createItems($0, withToken: token) }
        let newList = newListOfList.flatMap { return $0 }
        return newList
    }

    public func defaultLoadFrom(_ data: CNLDictionary) -> [ArrayElement] {
        let items: [[ArrayElement]] = tokens.flatMap {
            guard let itemsData = data[$0] as? CNLArray else { return nil }
            return defaultLoadFrom(itemsData, withToken: $0)
        }
        let result = items.flatMap { return $0 }
        return result
    }
    
    private func loadItems(_ data: CNLDictionary?, section: String) -> [ArrayElement]? {
        guard let itemsData = data?[section] as? CNLDictionary else { return nil }
        return defaultLoadFrom(itemsData)
    }
    
    public func createdItems(_ data: CNLDictionary?) -> [ArrayElement]? {
        return loadItems(data, section: "created")
    }
    
    public func modifiedItems(_ data: CNLDictionary?) -> [ArrayElement]? {
        return loadItems(data, section: "modified")
    }
    
    public func deletedItems(_ data: CNLDictionary?) -> [ArrayElement.KeyType]? {
        guard let idsData = data?["deleted"] as? CNLDictionary else { return nil }
        let ids: [[ArrayElement.KeyType]] = tokens.flatMap { token in
            return idsData[token] as? [ArrayElement.KeyType]
        }
        let result = ids.flatMap { return $0 }
        return result
    }
    
    public func loadFromDictionary(_ data: CNLDictionary) -> [ArrayElement] {
        lastTimestamp = data.date("timestamp") ?? lastTimestamp
        return defaultLoadFrom(data)
    }
    
    public func storeToDictionary() -> CNLDictionary {
        var result: CNLDictionary = [:]
        tokens.forEach { token in
            result[token] = list
                .filter { item in return item.token == token }
                .map { item in return item.storeToDictionary() }
        }
        result["timestamp"] = lastTimestamp?.timeIntervalSince1970
        return result
    }

    public func indexOf(item: ArrayElement) -> Int? {
        return self.list.index { return $0.primaryKey == item.primaryKey && $0.token == item.token }
    }

    // states
    public func updateStatesFromDictionary(_ data: CNLDictionary) {
        tokens.forEach { token in
            if let tokenData = data[token] as? CNLArray {
                tokenData.forEach { itemInfo in
                    guard let key: ArrayElement.KeyType = itemInfo.value("id") else { return }
                    self.updateStatesFromDictionary(itemInfo, forItemKey: key, withToken: token)
                }
            }
        }
    }
    
    public func updateStatesFromDictionary(_ data: CNLDictionary, forItemKey itemKey: ArrayElement.KeyType, withToken token: CNLModelObjectToken) {
        let items = list.filter { item in return item.token == token && item.primaryKey == itemKey }
        items.forEach { item in
            updateStatesFromDictionary(data, forItem: item)
        }
    }

    public init?(dictionary: CNLDictionary?) {
        self.init()
        if let data = dictionary {
            list = loadFromDictionary(data)
        } else {
            return nil
        }
    }
    
}
