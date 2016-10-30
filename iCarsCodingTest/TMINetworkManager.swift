//
//  TMINetworkManager.swift
//  KamcordProgrammingChallenge
//
//  Created by Nicholas Iannone on 9/20/16.
//  Copyright © 2016 Tiny Mobile Inc. All rights reserved.
//

import UIKit

protocol TMINetworkManagerDelegate : class {
    func didFinishNetworkCall(withResults results: Data, fromManager manager: TMINetworkManager)
}

class TMINetworkManager : NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    //member fields
    private var _configuration : URLSessionConfiguration
    private var _headers : [String: String]
    private var _session : URLSession?
    private var _data : Data?

    private weak var _delegate : TMINetworkManagerDelegate?

    //member computed properties
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
    
    //initialization
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
    
    public convenience init(withConfiguration configuration: URLSessionConfiguration, andDelegate delegate: TMINetworkManagerDelegate) {
            self.init(withConfiguration: configuration, delegate: delegate, andHeaders: [:])
    }
    
    public convenience init(withHeaders headers: [String : String], andDelegate delegate: TMINetworkManagerDelegate) {
        let sessionConfig = URLSessionConfiguration.ephemeral
        self.init(withConfiguration: sessionConfig, delegate: delegate, andHeaders: headers)
    }
    public convenience init(withDelegate delegate: TMINetworkManagerDelegate) {
        let sessionConfig = URLSessionConfiguration.ephemeral
        self.init(withConfiguration: sessionConfig, delegate: delegate, andHeaders: ["":""])
    }
    
    public func addDataTaskToSession(withURLString URLString: String) {
        if let endpoint = URL(string:URLString) {
            let request = URLRequest(url:endpoint)
            if let task = _session?.dataTask(with: request) {
                task.resume()
            }
        }
    }
    
    public func addDownloadTaskToSession(withURLString URLString: String) {
        if let endpoint = URL(string:URLString) {
            if _session != nil {
                let task =  _session!.downloadTask(with: endpoint)
                task.resume()
            }
        }
    }
    
    //delegate methods
    internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if (error != nil){
            print(error)
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


