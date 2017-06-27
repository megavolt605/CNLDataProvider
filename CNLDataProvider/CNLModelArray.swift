//
//  CNLModelArray.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 23/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

/// Array model, class only
/// Declares basic functions to map, load and store received data
public protocol CNLModelArray: class, CNLDataSourceModel {
    
    /// Maps (deserialize) received dictionary to the model ArrayElement object
    ///
    /// - Parameter data: Source data dictionary
    func createItems(_ data: CNLDictionary) -> [ArrayElement]?
    
    /// Maps (deserialize) received array to the model ArrayElement item instancies
    ///
    /// - Parameter array: Source data array
    func loadFromArray(_ array: CNLArray) -> [ArrayElement]
    
    /// Returns mapped (serialized) array
    func storeToArray() -> CNLArray
    
    /// Point of making necessary changes after serialize
    ///
    /// - Parameter newList: Source array of model items (ArrayEement)
    /// - Returns: Updated array
    func afterLoad(_ newList: [ArrayElement]) -> [ArrayElement]
    
    /// Extract dictionary element to perform desealisation by loadFromArray(_:), createItems(_:), etc.
    ///
    /// - Parameter json: Source dictionary
    /// - Returns: New array
    func rows(_ json: CNLDictionary?) -> CNLArray?
    
    /// Preprocess incoming dictionary data
    ///
    /// - Parameter data: Source dictionary
    /// - Returns: Updated dictionary
    func preprocessData(_ data: CNLDictionary?) -> CNLDictionary?
    
    /// Default initializer
    init()
}

public extension CNLModelObject where Self: CNLModelArray {
    
    public func createItems(_ data: CNLDictionary) -> [ArrayElement]? {
        if let item = ArrayElement(dictionary: data) {
            return [item]
        }
        return nil
    }
    
    public func loadFromArray(_ array: CNLArray) -> [ArrayElement] {
        return defaultLoadFrom(array)
    }
    
    public func afterLoad(_ newList: [ArrayElement]) -> [ArrayElement] { return newList }
    
    public func rows(_ json: CNLDictionary?) -> CNLArray? {
        return json?["rows"] as? CNLArray
    }
    
    public func preprocessData(_ data: CNLDictionary?) -> CNLDictionary? {
        return data
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
    
    public func update(success: @escaping CNLModel.Success, failed: @escaping CNLModel.Failed) {
        if let localAPI = createAPI() {
            CNLModel.networkProvider?.performRequest(
                api: localAPI,
                success: { apiObject in
                    let data = self.preprocessData(apiObject.answerJSON)
                    if let json = self.rows(data) {
                        self.list = self.loadFromArray(json)
                    } else {
                        self.list = self.loadFromArray([])
                    }
                    #if DEBUG
                        CNLLog("Model count: \(self.list.count)", level: .debug)
                    #endif
                    if let value: Int = data?.value("total") {
                        self.totalRecords = value
                    } else {
                        self.totalRecords = self.list.count
                    }
                    success(self, apiObject.status)
            },
                fail: { apiObject in
                    failed(self, apiObject.errorStatus)
            },
                networkError: { apiObject, error in
                    failed(self, apiObject.errorStatus(error))
            }
            )
        } else {
            list = loadFromArray([])
            success(self, okStatus) //(kind: CNLErrorKind.Ok, success: true))
        }
    }
    
    public func defaultLoadFrom(_ array: CNLArray) -> [ArrayElement] {
        let newListOfList = array.mapSkipNil { return self.createItems($0) }
        let newList = newListOfList.flatMap { return $0 }
        additionalRecords += newList.count - newListOfList.count
        return afterLoad(newList)
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

public protocol CNLModelArrayKeyStored: CNLModelArray, CNLModelObjectPrimaryKey {
    
}
