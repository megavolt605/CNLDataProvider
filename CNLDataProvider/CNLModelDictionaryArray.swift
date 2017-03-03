//
//  CNLModelDictionaryArray.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 23/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

public protocol CNLModelDictionaryArray: class {
    associatedtype DictionaryElement: CNLModelDictionaryKeyStored
    var list: [DictionaryElement.KeyType:DictionaryElement] {get set}
    func storeToDictionaryArray() -> CNLArray
    func loadFromDictionaryArray(_ array: CNLArray)
    func reset()
    init()
    init?(array: CNLArray?)
}

extension CNLModelObject where Self: CNLModelDictionaryArray {
    
    public func reset() {
        list = [:]
    }
    
    public init?(array: CNLArray?) {
        self.init()
        if let data = array {
            loadFromDictionaryArray(data)
        } else {
            return nil
        }
    }
    
    public func loadFromDictionaryDictionary(_ array: CNLArray) {
        list = array.mapSkipNil { data in
            if let item = DictionaryElement(dictionary: data) {
                return (key: item.primaryKey, value: item)
            }
            return nil
        }
    }
    
    public func storeToDictionaryDictionary() -> CNLArray {
        let captureList = list
        return captureList.map { data in data.value.storeToDictionary() }
    }
    
}

public protocol CNLModelDictionaryDictionary: class {
    associatedtype DictionaryElement: CNLModelArrayKeyStored
    var list: [DictionaryElement.KeyType:DictionaryElement] {get set}
    func storeToDictionaryDictionary() -> CNLDictionary
    func loadFromDictionaryDictionary(_ array: CNLDictionary)
    func reset()
    init()
    init?(array: CNLArray?)
}

extension CNLModelObject where Self: CNLModelDictionaryDictionary {
    
    public func reset() {
        list = [:]
    }
    
    public func loadFromDictionaryDictionary(array: CNLDictionary) {
        list = array.mapSkipNil { key, value in
            if let value = value as? CNLArray, let item = DictionaryElement(keyValue: key) {
                item.list = item.loadFromArray(value)
                return (key: item.primaryKey, value: item)
            }
            return nil
        }
    }
    
    public func storeToDictionaryDictionary() -> CNLDictionary {
        let captureList = list
        let result: CNLDictionary = captureList.mapSkipNil { key, value in
            if let k = value.encodedPrimaryKey {
                return (key: k, value: value.storeToArray())
            }
            return nil
        }
        return result
    }
    
    public init?(array: CNLDictionary?) {
        self.init()
        if let data = array {
            loadFromDictionaryDictionary(data)
        } else {
            return nil
        }
    }
    
}
