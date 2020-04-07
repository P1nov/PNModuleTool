//
//  PNModuleRouter.swift
//  PNModuleTool
//
//  Created by 雷永麟 on 2020/4/1.
//  Copyright © 2020 leiyonglin. All rights reserved.
//

import UIKit

public protocol PNModuleRoutable {
    
    static var routePath : String { get }
}

public typealias ModuleRouterHandler = (_ paramter : [String : String]?, _ controller : UIViewController) -> UIViewController?

public class PNModuleRouter: NSObject {

    public static var `default` = PNModuleRouter()
    
    fileprivate static var routes : [String : ModuleRouterHandler] = {
       
        var routes : [String : ModuleRouterHandler] = [:]
        
        return routes
    }()
    
    public static func registModuleRouter(_ url : String, _ handler : @escaping ModuleRouterHandler) {
        
        let url = URL(string: "/\(url)")
        guard let host = url?.host, let path = url?.path else { return }
        
        let routerURL = "\(host)\(path)"
        
        routes[routerURL] = handler
    }
    
    public static func defaultRoute(_ routerURL : String, _ fromViewController : UIViewController, completion : (() -> Void)?) {
        
        if routerURL.contains("http://") || routerURL.contains("https://") {
            
            
        }else {
            
            self.route(routerURL, fromViewController, completion: completion)
        }
    }
    
    public static func route(_ routerURL : String, _ fromViewController : UIViewController, completion : (() -> Void)?) {
        
        let percentRouterURL = routerURL.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        
        let url = URL(string: "/\(percentRouterURL ?? routerURL)")
        let router = "\(url?.host ?? "")\(url?.path ?? "")"
        
        let paramter = PNModuleRouter.decodeUrlParamter(percentRouterURL ?? routerURL)
        
        if let moduleHandler = self.routes[router] {
            
            guard let toController = moduleHandler(paramter, fromViewController) else { return }
            
            if let paramDic = paramter {
                
                paramDic.forEach { (key, value) in
                    
                    toController.setValue(value, forKey: key)
                }
            }
            
            if fromViewController is UINavigationController {
                
                (fromViewController as! UINavigationController).pushViewController(toController, animated: true)
            }else {
                
                fromViewController.present(toController, animated: true, completion: completion)
            }
        }
    }
    
    public static func configRouter() {
        
        let typeCount = Int(objc_getClassList(nil, 0))
        
        let types = UnsafeMutablePointer<AnyClass>.allocate(capacity: typeCount)
        
        let autoreleasingTypes = AutoreleasingUnsafeMutablePointer<AnyClass>(types)
        
        objc_getClassList(autoreleasingTypes, Int32(typeCount))
        
        for index in 0 ..< typeCount {
            
            if let routable = types[index] as? PNModuleRoutable.Type {
                
                self.registModuleRouter(routable.routePath) { (paramter, fromViewController) -> UIViewController? in
                    
                    if let controller = types[index] as? UIViewController.Type {
                        
                        return controller.init()
                    }else {
                        
                        return nil
                    }
                }
            }
        }
        types.deallocate()
    }
}

extension PNModuleRouter {
    
    fileprivate static func decodeUrlParamter(_ url : String) -> [String : String]? {
        
        let url = URL(string: "/\(url)")
        
        if let urlQuery = url?.query {
            
            var urlParamter : [String : String] = [:]
            
            let paramters = urlQuery.components(separatedBy: "&")
            
            paramters.forEach { (subParamter) in
                
                let subParamters = subParamter.components(separatedBy: "=")
                
                if subParamters.count > 1 {
                    var subValue = subParamters[1]
                    subValue = subValue.removingPercentEncoding ?? subValue
                    urlParamter[subParamters[0]] = subValue
                }else {
                    urlParamter[subParamters[0]] = ""
                }
            }
            
            return urlParamter
        }else {
            
            return nil
        }
    }
    
    static func canHandleURL(url : String) -> Bool {
        
        if url.isEmpty {
            
            return false
        }
        
        guard let _ = handler(for: url) else { return false }
        
        return true
    }
    
    static func handler(for url : String) -> ModuleRouterHandler? {
        
        return self.routes[url]
    }
}
