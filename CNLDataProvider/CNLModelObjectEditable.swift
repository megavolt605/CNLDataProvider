//
//  RPModelObjectEditable.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 23/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

public protocol CNLModelObjectEditable {
    var editing: Bool { get set }
    func updateList()
}
