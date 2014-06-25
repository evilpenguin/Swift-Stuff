//
//  Set.swift
//
//  Created by James D. Emrich on 6/24/14.
//  Copyright (c) 2014 James D. Emrich. All rights reserved.
//

import Foundation

class Set<T: Equatable> {
    @lazy var map: Dictionary<String, T> = {
        return Dictionary<String, T>();
    }();
    
    // Return the count of the map
    var count: Int {
        get {
            return self.map.count;
        }
    }
    
    // Return the keys for the map
    var keys: Array<String> {
        get {
            return Array(self.map.keys);
        }
    };

    // Return if the map is empty or not
    func isEmpty() -> Bool {
        return self.map.count <= 0;
    }
    
    // Return if the map contains the element or not
    func contains(item: T) -> Bool {
        return self.map.indexForKey("\(item)") != nil;
    }
    
    // Insert the given item
    func insert(item: T) {
        if (!self.contains(item)) {
            self.map.updateValue(item, forKey: "\(item)");
        }
    }
    
    // Add the given item
    func add(item: T) {
        self.insert(item);
    }
    
    // Remove the give item
    func remove(item: T) {
        self.map.removeValueForKey("\(item)");
    }
    
    // Clear the entire map, remove capacity
    func clear(keepCapacity: Bool = false) {
        self.map.removeAll(keepCapacity: keepCapacity);
    }
    
    // Clone the map, and return a set 
    // O(n)
    func clone() -> Set {
        var cloneDictionary = Set();

        for key: String in self.map.keys {
            if let item = self[key] {
                cloneDictionary.insert(item);
            }
        }
        
        return cloneDictionary;
    }
    
    // Add subscripting based on key: String
    subscript(key: String) -> T? {
        return self.map[key];
    }
}