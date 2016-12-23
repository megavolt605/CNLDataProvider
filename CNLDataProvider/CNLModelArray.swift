//
//  CNLModelArray.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 23/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

public var kCNLModelDefaultPageLimit: Int = 20

private var pagingArrayFromIndex = "fromIndex"
private var pagingArrayTotalRecords = "totalRecords"
private var pagingArrayAdditionalRecords = "additionalRecords"

// MARK: - CNLModelArray protocol
public protocol CNLModelArray: class {
    associatedtype ArrayElement: CNLModelDictionary
    var list: [ArrayElement] { get set }
    var isPagingEnabled: Bool { get }
    var fromIndex: Int { get set }
    var totalRecords: Int? { get set }
    var additionalRecords: Int { get set }
    func pagingReset()
    
    func reset()
    func createItems(_ data: CNLDictionary) -> [ArrayElement]?
    func loadFromArray(_ array: CNLArray)
    func storeToArray() -> CNLArray
    func updateArray()
    func updateArray(success: @escaping CNLModelCompletion, failed: @escaping CNLModelFailed)
    func afterLoad(_ newList: [ArrayElement])
    func rows(_ json: CNLDictionary?) -> CNLArray?
    func preprocessData(_ data: CNLDictionary?) -> CNLDictionary?
    init()
}

public extension CNLModelObject where Self: CNLModelArray {
    
    public var pageLimit: Int { return isPagingEnabled ? kCNLModelDefaultPageLimit : -1 }
    public var isPagingEnabled: Bool { return false }
    
    public func reset() {
        list = []
    }
    
    public func createItems(_ data: CNLDictionary) -> [ArrayElement]? {
        if let item = ArrayElement(dictionary: data) {
            return [item]
        }
        return nil
    }
    
    public func loadFromArray(_ array: CNLArray) {
        defaultLoadFrom(array)
    }
    
    public func afterLoad(_ newList: [ArrayElement]) { }
    
    public func rows(_ json: CNLDictionary?) -> CNLArray? {
        //print(json?["rows"] as? CNLModelArray)
        return json?["rows"] as? CNLArray
    }
    
    public func preprocessData(_ data: CNLDictionary?) -> CNLDictionary? {
        return data
    }
    
    public func pagingReset() {
        //reset()
        fromIndex = 0
        totalRecords = nil
        additionalRecords = 0
    }
    
    public final var fromIndex: Int {
        get {
            if let value = (objc_getAssociatedObject(self, &pagingArrayFromIndex) as? CNLAssociated<Int>)?.closure {
                return value
            } else {
                return 0
            }
        }
        set {
            objc_setAssociatedObject(self, &pagingArrayFromIndex, CNLAssociated<Int>(closure: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public final var totalRecords: Int? {
        get {
            if let value = (objc_getAssociatedObject(self, &pagingArrayTotalRecords) as? CNLAssociated<Int?>)?.closure {
                return value
            } else {
                return nil
            }
        }
        set {
            objc_setAssociatedObject(self, &pagingArrayTotalRecords, CNLAssociated<Int?>(closure: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public final var additionalRecords: Int {
        get {
            if let value = (objc_getAssociatedObject(self, &pagingArrayAdditionalRecords) as? CNLAssociated<Int>)?.closure {
                return value
            } else {
                return 0
            }
        }
        set {
            objc_setAssociatedObject(self, &pagingArrayAdditionalRecords, CNLAssociated<Int>(closure: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public func storeToArray() -> CNLArray {
        let captureList = list
        return captureList.map() { $0.storeToDictionary() }
    }
    
    public static func loadFromArray(_ array: CNLArray?) -> Self? {
        guard let array = array else { return nil }
        let result = Self()
        result.loadFromArray(array)
        return result
    }
    
    public func updateArray() {
        updateArray(success: { model, status in }, failed: { model, error in } )
    }
    
    public func updateArray(success: @escaping CNLModelCompletion, failed: @escaping CNLModelFailed) {
        if let localAPI = createAPI() {
            CNLModelNetworkProvider?.performRequest(
                api: localAPI,
                success: { apiObject in
                    let data = self.preprocessData(apiObject.answerJSON)
                    if let json = self.rows(data) {
                        self.loadFromArray(json)
                    } else {
                        self.loadFromArray([])
                    }
                    print("Model count: \(self.list.count)")
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
            loadFromArray([])
            success(self, okStatus) //(kind: CNLErrorKind.Ok, success: true))
        }
    }
    
    public func defaultLoadFrom(_ array: CNLArray) {
        let newListOfList = array.mapSkipNil { return self.createItems($0) }
        let newList = newListOfList.flatMap { return $0 }
        additionalRecords += newList.count - newListOfList.count
        list = newList
        afterLoad(newList)
    }
    
    public init?(array: CNLArray?) {
        self.init()
        if let data = array {
            loadFromArray(data)
        } else {
            return nil
        }
    }
    
}

public protocol CNLModelArrayKeyStored: CNLModelArray, CNLModelObjectPrimaryKey {
    
}
