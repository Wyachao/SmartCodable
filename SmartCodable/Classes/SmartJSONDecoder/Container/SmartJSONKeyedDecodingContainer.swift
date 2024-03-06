//
//  SmartJSONKeyedDecodingContainer.swift
//  SmartCodable
//
//  Created by Mccc on 2024/3/4.
//

import Foundation

struct SmartJSONKeyedDecodingContainer<K : CodingKey>: KeyedDecodingContainerProtocol {
    
    typealias Key = K
    
    // MARK: Properties
    
    /// A reference to the decoder we're reading from.
    let decoder: _SmartJSONDecoder
    
    /// A reference to the container we're reading from.
    let container: [String : Any]
    
    /// The path of coding keys taken to get to this point in decoding.
    internal(set) public var codingPath: [CodingKey]
    
    // MARK: - Initialization
    
    /// Initializes `self` by referencing the given decoder and container.
    init(referencing decoder: _SmartJSONDecoder, wrapping container: [String : Any]) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
        self.container = container
    }
    
    // MARK: - KeyedDecodingContainerProtocol Methods
    
    public var allKeys: [Key] {
        return self.container.keys.compactMap { Key(stringValue: $0) }
    }
    
    public func contains(_ key: Key) -> Bool {
        return self.container[key.stringValue] != nil
    }
    
    
}



extension SmartJSONKeyedDecodingContainer {
    public func decodeNil(forKey key: Key) throws -> Bool {
        
        guard let entry = self.container[key.stringValue] else {

            // ⚠️： 输出日志信息
//            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
            return true
        }
        return entry is NSNull
    }
    
   
    @inline(__always)
    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        /// ⚠️： 如果不存在key时，创建一个空的字典容器返回，即提供一个空字典作为默认值。是否合理？
        guard let value = self.container[key.stringValue] else {
            
            /// ⚠️日志信息： 抛出这样的日志，方便排查问题。
//            throw DecodingError.keyNotFound(key,
//                                            DecodingError.Context(codingPath: self.codingPath,
//                                                                  debugDescription: "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found for key \"\(key.stringValue)\""))
            
            return nestedContainer(wrapping: [:])
        }
        
        /// ⚠️： 如果value不是字典类型，创建一个空的字典容器返回。
        guard let dictionary = value as? [String : Any] else {
            /// ⚠️日志信息： 抛出这样的日志，方便排查问题。
//            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : Any].self, reality: value)

            return nestedContainer(wrapping: [:])
        }
        
        return nestedContainer(wrapping: dictionary)
    }
    
    @inline(__always)
    private func nestedContainer<NestedKey>(wrapping dictionary: [String: Any]) -> KeyedDecodingContainer<NestedKey> {
        let container = SmartJSONKeyedDecodingContainer<NestedKey>(referencing: decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }
    
    @inline(__always)
    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        guard let value = self.container[key.stringValue] else {
            /// ⚠️日志信息： 抛出这样的日志，方便排查问题。
//            throw DecodingError.keyNotFound(key,
//                                            DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get UnkeyedDecodingContainer -- no value found for key \"\(key.stringValue)\""))
  
            return SmartSONUnkeyedDecodingContainer(referencing: self.decoder, wrapping: [])
        }
        
        guard let array = value as? [Any] else {
            /// ⚠️日志信息： 抛出这样的日志，方便排查问题。
//            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: value)

            return SmartSONUnkeyedDecodingContainer(referencing: self.decoder, wrapping: [])
        }
        
        return SmartSONUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }
    
    
    
    @inline(__always)
    public func superDecoder() throws -> Decoder {
        return try _superDecoder(forKey: SmartCodingKey.super)
    }
    
    @inline(__always)
    public func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
    
    @inline(__always)
    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        
        let value: Any = self.container[key.stringValue] ?? NSNull()
        return _SmartJSONDecoder(referencing: value, at: self.decoder.codingPath, options: self.decoder.options)
    }
}


extension SmartJSONKeyedDecodingContainer {
    func didFinishMapping<T: Decodable>(_ decodeValue: T) -> T {
        return DecodingProcessCoordinator.didFinishMapping(decodeValue)
    }

}