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
    
    var tokenizedList: [CNLModelObjectToken: ArrayElement] { get }
    var tokens: [String] { get set }
    func reset()
    func createItems(_ data: CNLDictionary, withToken token: CNLModelObjectToken) -> [ArrayElement]?
}

public protocol CNLModelObjectTokenized: CNLModelObject, CNLModelObjectPrimaryKey {
    static var token: CNLModelObjectToken { get }
}

public extension CNLModelObject where Self: CNLModelIncrementalTokenizedArray {
    
    public func reset() {
        list = []
    }
    
    public func createItems(_ data: CNLDictionary, withToken token: CNLModelObjectToken) -> [ArrayElement]? {
        if let item = ArrayElement(dictionary: data) {
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
    
    private func createdItems(_ data: CNLDictionary?) -> [ArrayElement]? {
        return loadItems(data, section: "created")
    }
    
    private func modifiedItems(_ data: CNLDictionary?) -> [ArrayElement]? {
        return loadItems(data, section: "modified")
    }
    
    func deletedItems(_ data: CNLDictionary?) -> [ArrayElement.KeyType]? {
        guard let idsData = data?["deleted"] as? CNLDictionary else { return nil }
        let ids: [[ArrayElement.KeyType]] = tokens.flatMap { token in
            return idsData[token] as? [ArrayElement.KeyType]
        }
        let result = ids.flatMap { return $0 }
        return result
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
