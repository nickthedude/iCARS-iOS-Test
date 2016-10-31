//
//  TMINetworkManager.swift
//  KamcordProgrammingChallenge
//
//  Created by Nicholas Iannone on 9/20/16.
//  Copyright © 2016 Tiny Mobile Inc. All rights reserved.
//

import UIKit
// MARK: - TMINetworkManagerDelegate Protocol
protocol TMINetworkManagerDelegate : class {
    func didFinishNetworkCall(withResults results: Data, fromManager manager: TMINetworkManager)
}
// MARK: - TMINetworkManager Class
class TMINetworkManager : NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    // MARK: - Member Fields (Private)
    /// Internal configuration object.
    private var _configuration : URLSessionConfiguration
    /// Internal header dictionary [String : String].
    private var _headers : [String: String]
    /// Internal URLSession object optional.
    private var _session : URLSession?
    /// Data received from endpoint is stored here as it is retrieved.
    private var _data : Data?
    /// Object to be called when assigned task(s) are complete.
    private weak var _delegate : TMINetworkManagerDelegate?

    // MARK: - Public versions of Member fields 

    public func configuration() -> URLSessionConfiguration? {
        if let retVal = session()?.configuration {
            return retVal
        }
        else { return nil }
    }
    public func headers() -> [String : String] {
        return _headers
    }
    public func session() -> URLSession? {
        return _session
    }
    public func delegate() -> AnyObject? {
        return _delegate
    }
    public func setDelegate(delegate : TMINetworkManagerDelegate) {
         _delegate = delegate
    }
    // MARK: - Initializers

    /// Designated initializer for class.
    public init(withConfiguration configuration: URLSessionConfiguration, delegate: TMINetworkManagerDelegate, andHeaders headers : [String : String]) {
        configuration.httpAdditionalHeaders = headers
        _configuration = configuration
        _headers = headers
        super.init()
        _session = URLSession(configuration: configuration,
                              delegate: self,
                              delegateQueue:nil)
        _delegate = delegate
    }
    /// Convenience Initializer of the TMINetworkManager class.
    /// - Parameters:
    ///     - withConfiguration: URLSessionConfiguration configured for desired endpoint
    ///     - andDelegate: Instance to be called when receiving a response to a network query.
    public convenience init(withConfiguration configuration: URLSessionConfiguration, andDelegate delegate: TMINetworkManagerDelegate) {
            self.init(withConfiguration: configuration, delegate: delegate, andHeaders: [:])
    }
    /// Convenience Initializer of the TMINetworkManager class.
    /// - Parameters:
    ///     - withHeaders: Headers [String : String] dictionary configured for desired endpoint
    ///     - andDelegate: Instance to be called when receiving a response to a network query.
    public convenience init(withHeaders headers: [String : String], andDelegate delegate: TMINetworkManagerDelegate) {
        let sessionConfig = URLSessionConfiguration.ephemeral
        self.init(withConfiguration: sessionConfig, delegate: delegate, andHeaders: headers)
    }
    /// Convenience Initializer of the TMINetworkManager class.
    /// - Parameters:
    ///     - withDelegate: Instance to be called when receiving a response to a network query.
    public convenience init(withDelegate delegate: TMINetworkManagerDelegate) {
        let sessionConfig = URLSessionConfiguration.ephemeral
        self.init(withConfiguration: sessionConfig, delegate: delegate, andHeaders: ["":""])
    }
    // MARK: - Add tasks to Manager
    
    /// Public method used to add a data task to TMINetworkManager in the form of a String encoded URL. Typically used to retrieve JSON data.
    /// - Parameters:
    ///     - withURLString: URL encoded as String.
    public func addDataTaskToSession(withURLString URLString: String) {
        if let endpoint = URL(string:URLString) {
            let request = URLRequest(url:endpoint)
            if let task = _session?.dataTask(with: request) {
                task.resume()
            }
        }
    }
    /// Public method used to add a download task to TMINetworkManager in the form of a String encoded URL. Typically used to retrieve media.
    /// - Parameters:
    ///     - withURLString: URL encoded as String.
    public func addDownloadTaskToSession(withURLString URLString: String) {
        if let endpoint = URL(string:URLString) {
            if _session != nil {
                let task =  _session!.downloadTask(with: endpoint)
                task.resume()
            }
        }
    }
    
    // MARK: - URLSession Delegate methods
    internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if (error != nil){
            print(error ?? "error with url session")
        }
        else {
            if(_data != nil) {
             _delegate?.didFinishNetworkCall(withResults: _data!, fromManager: self)
            }
        }
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if _data == nil {
            _data = Data()
        }
        _data?.append(data)
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void){
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, nil)
    }
    
}


