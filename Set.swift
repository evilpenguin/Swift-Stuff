//
//  Set.swift
//
//  Created by James D. Emrich on 6/24/14.
//  Copyright (c) 2014 James D. Emrich. All rights reserved.
//

struct SetGenerator<KeyType: Hashable> : Generator {
    var _base: DictionaryGenerator<KeyType, ()>;
    mutating func next() -> KeyType? { return self._base.next()?.0 }
}

struct Set<T: Hashable> {
    var _map: Dictionary<T, ()> = [:];
    
    // Return the count of the map
    var count: Int {
        get {
            return self._map.count;
        }
    }
    
    // Return the values for the map
    var values: MapCollectionView<Dictionary<T, ()>, T> {
        get {
            return self._map.keys;
        }
    }

    // Return if the map is empty or not
    func isEmpty() -> Bool {
        return self.count <= 0;
    }
    
    // Return if the map contains the element or not
    func contains(item: T) -> Bool {
        return self._map[item] != nil;
    }
    
    // Insert the given item
    mutating func insert(item: T) {
        self._map[item] = ();
    }

    // Remove the give item
    mutating func remove(item: T) {
        self._map.removeValueForKey(item);
    }
    
    // Clear the entire map, remove capacity
    mutating func clear(keepCapacity: Bool = false) {
        self._map.removeAll(keepCapacity: keepCapacity);
    }
    
    // Make the set enumerable
    func generate() -> SetGenerator<T> {
        return SetGenerator(_base: self._map.generate());
    }
}