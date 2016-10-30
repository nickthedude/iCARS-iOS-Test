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
    
    private var _mapView: GMSMapView!

    private var _shouldSuspendLocationUpdates  = false

    @IBOutlet private var _sideMenu: UIView!
    
    private var _sideMenuIsOnsceen  = false
    
    private var _markers : [GMSMarker] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGPS()
        setupMap()
        stylizeSideMenu()
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
        
        _camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: _mapView.camera.zoom)
        _mapView.camera = _camera
        
 
    }
    
    /// Function that initializes the Google Map services object with an API key retieved from a local config file(configuration.plist). A camera position is aplied and the MapViewController's view is set to an instance of the GMSMapView Class.
    func setupMap()  {
        GMSServices.provideAPIKey(self.getConfigDictionary()!["googleMapsAPIKey"] as! String)
        _camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        _mapView = GMSMapView.map(withFrame: view.frame, camera: _camera)
        _mapView.isMyLocationEnabled = true
        view = _mapView
        
        view.addSubview(_sideMenu)
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
        if !_shouldSuspendLocationUpdates {
            updateMapViewToLocation(latitude: locations[0].coordinate.latitude , longitude: locations[0].coordinate.longitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    
        print("location error")

    }
    
    /// Function that configures this View Controller's parenting Navigation Controller to display a title as well as creating and adding a 'Menu' button that the user may interact with.
    func setupNavigationController()  {
        title = "iCars Test"
        let menuButton = UIBarButtonItem.init(title:"Menu", style:.plain, target: self, action:#selector(MapViewController.menuButtonPressed))
        navigationItem.rightBarButtonItem = menuButton
        if let navFont = UIFont(name: "HelveticaNeue-Light", size: 17.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navFont
            ]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
        }
    }
    
    /// Action triggered when the user presses the 'Menu' button located inside the navigation controller's navigation bar.
    func menuButtonPressed() {
        toggleSideMenuOnScreen()
        
    }
    
    /// Adjusts a side menu View frame. This display of this side menu will be the response to a user tapping the 'Menu' button in the navigation bar.
    func adjustSideMenuForParentsCurrentFrame() {
       // let sideMenuView
        _sideMenu.frame = CGRect(x: view.frame.width, y: (view.frame.height * 0.08), width: _sideMenu.frame.width, height: _sideMenu.frame.height)

    }
    
    func stylizeSideMenu() {
        //only apply the blur if transparency effects are enabled
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            _sideMenu.backgroundColor = UIColor.clear
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.frame = _sideMenu.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            _sideMenu.insertSubview(blurEffectView, at: 0)
            blurEffectView.clipsToBounds = true
        }
    }

    
    func toggleSideMenuOnScreen() {
        let distanceMultiplier : CGFloat = 0.6
        if _sideMenuIsOnsceen {
            // move sideMenu Off-screen
            UIView.beginAnimations(nil, context: nil)
            _sideMenu.center = CGPoint(x: (_sideMenu.center.x + (view.frame.size.width * distanceMultiplier)), y: _sideMenu.center.y)
            UIView.commitAnimations()
            _sideMenuIsOnsceen = false

            
        } else {
            // move sideMenu On-screen
            UIView.beginAnimations(nil, context: nil)
            _sideMenu.center = CGPoint(x: (_sideMenu.center.x - (view.frame.size.width * distanceMultiplier)), y: _sideMenu.center.y)
            UIView.commitAnimations()
            _sideMenuIsOnsceen = true

        }
        
    }
    @IBAction func newYorkButtonPressed(_ sender: AnyObject) {
        toggleSideMenuOnScreen()
        let latitude = 40.7128, longitude = -74.0059
        _shouldSuspendLocationUpdates = true
        placeMarkerOnMapfor(latitude: latitude, longitude: longitude, title: "New York City", snippet: "United States")
        updateMapViewToLocation(latitude: latitude, longitude:longitude )
    }
    @IBAction func SFButtonPressed(_ sender: AnyObject) {
        //37.7749° N, 122.4194° W
        toggleSideMenuOnScreen()
        let latitude = 37.7749, longitude = -122.4194
        _shouldSuspendLocationUpdates = true
        placeMarkerOnMapfor(latitude: latitude, longitude: longitude, title: "San Francisco", snippet: "United States")
        updateMapViewToLocation(latitude: latitude, longitude:longitude )
    }
    @IBAction func SFToNYButtonPressed(_ sender: AnyObject) {
    }
    
    func placeMarkerOnMapfor(latitude: Double, longitude: Double, title: String?, snippet: String?) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude:latitude, longitude: longitude)
        if let titleString = title {
            marker.title = titleString
        }
        if let snippetString = snippet {
            marker.snippet = snippetString
        }
        marker.map = _mapView
    }
    
    
}



