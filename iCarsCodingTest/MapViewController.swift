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

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGPS()
        setupMap()
        
        
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
    
    /// Function that initializes the Google Map services object with an API key retieved from a local config file. A camera position is aplied and the MapViewController's view is set to an instance of the GMSMapView Class.
    func setupMap()  {
        GMSServices.provideAPIKey(self.getConfigDictionary()!["googleMapsAPIKey"] as! String)
        _camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: _camera)
        mapView.isMyLocationEnabled = true
        view = mapView
        
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
       print("button pressed")
    }
    
    func setupEdgeMenu() {

    }
    
    func createButtonForSideMenu(title: String, action: String, color : UIColor) -> UIButton {
        let button = UIButton.init(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        let sel = Selector.init(action)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.addTarget(self, action: sel, for: .touchUpInside)
        return button
        
    }
}



