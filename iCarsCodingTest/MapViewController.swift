//
//  ViewController.swift
//  iCarsCodingTest
//
//  Created by Nicholas Iannone on 10/28/16.
//  Copyright © 2016 Tiny Mobile Inc. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation

class MapViewController: UIViewController , CLLocationManagerDelegate {

    /// CoreLocation CLLocation manager member variable
    private var _locationManager  = CLLocationManager()
    
    /// Google Maps camera object member variable used to manipulate the viewing bounds of a GMSMapView object
    private var _camera = GMSCameraPosition.camera(withLatitude: 0.0, longitude: 0.0, zoom: 6.0)

    @IBOutlet private var _sideMenu: UIView!
    
    private var _sideMenuIsOnsceen  = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGPS()
        setupMap()
        adjustSideMenuForParentsCurrentFrame()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupNavigationController()

    }
    
    /// retrieves the configuration dictionary from the main app bundle. The caller of this function is responsible for extracting individual values from the returned Dictionary. If there is no config dictionary an optional containing a nil value is returned.
    func getConfigDictionary() -> [String : AnyObject]? {
        let path = Bundle.main.path(forResource: "configuration", ofType: "plist")
        if let dict = NSDictionary(contentsOfFile: path!) as? [String : AnyObject] {
            return dict
        }
        else {
            return nil
        }
    }
    
    ///Convienence method for updating the _camera's viewable area based on the latitude and longitude parameters
    /// - Parameter latitude: a latitude in Double format used to orient the _camera along a vertical axis
    /// - Parameter longitude: a longitude in Double format used to orient the _camera along a horizontal axis
    func updateMapViewToLocation(latitude: Double, longitude: Double) {
        let mapView = view as! GMSMapView

        _camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: mapView.camera.zoom)
        mapView.camera = _camera
        
        
    }
    
    /// Function that initializes the Google Map services object with an API key retieved from a local config file(configuration.plist). A camera position is aplied and the MapViewController's view is set to an instance of the GMSMapView Class.
    func setupMap()  {
        GMSServices.provideAPIKey(self.getConfigDictionary()!["googleMapsAPIKey"] as! String)
        _camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: view.frame, camera: _camera)
        mapView.isMyLocationEnabled = true
        view = mapView
        
        view.addSubview(_sideMenu)

        
//        // Creates a marker in the center of the map.
//        let marker = GMSMarker()
//        marker.position = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.20)
//        marker.title = "Sydney"
//        marker.snippet = "Australia"
//        marker.map = mapView

    }
    
    /// Function that sets up the Core Location CLLocationManager instance and configures it so that this app will receive updates about changes in the users location.
    func setupGPS()  {
        _locationManager.delegate = self
        _locationManager.distanceFilter = kCLDistanceFilterNone
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.requestWhenInUseAuthorization()
        _locationManager.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        updateMapViewToLocation(latitude: locations[0].coordinate.latitude , longitude: locations[0].coordinate.longitude)
        print("location received")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    
        print("location error")

    }
    
    /// Function that configures this View Controller's parenting Navigation Controller to display a title as well as creating and adding a 'Menu' button that the user may interact with.
    func setupNavigationController()  {
        title = "iCars Test"
        let menuButton = UIBarButtonItem.init(title:"Menu", style:.plain, target: self, action:#selector(MapViewController.menuButtonPressed))
        navigationItem.rightBarButtonItem = menuButton
        
    }
    
    /// Action triggered when the user presses the 'Menu' button located inside the navigation controller's navigation bar.
    func menuButtonPressed() {
        toggleSideMenuOnScreen()
        
    }
    
    /// Adjusts a side menu View frame. This display of this side menu will be the response to a user tapping the 'Menu' button in the navigation bar.
    func adjustSideMenuForParentsCurrentFrame() {
       // let sideMenuView
        _sideMenu.frame = CGRect(x: view.frame.width, y: (view.frame.height * 0.125), width: _sideMenu.frame.width, height: _sideMenu.frame.height)

    }
    
    func toggleSideMenuOnScreen() {
        if _sideMenuIsOnsceen {
            // move sideMenu Off-screen
            UIView.beginAnimations(nil, context: nil)
            _sideMenu.center = CGPoint(x: (_sideMenu.center.x + 200.0), y: _sideMenu.center.y)
            UIView.commitAnimations()
            _sideMenuIsOnsceen = false

            
        } else {
            // move sideMenu On-screen
            UIView.beginAnimations(nil, context: nil)
            _sideMenu.center = CGPoint(x: (_sideMenu.center.x - 200.0), y: _sideMenu.center.y)
            UIView.commitAnimations()
            _sideMenuIsOnsceen = true

        }
        
    }
    
}



