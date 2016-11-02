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


class MapViewController: UIViewController , CLLocationManagerDelegate, TMINetworkManagerDelegate, GMSMapViewDelegate {
    // MARK: - Properties
    @IBOutlet private var _sideMenu: UIView!
    /// CoreLocation CLLocation manager member variable.
    private var _locationManager  = CLLocationManager()
    /// Google Maps camera object member variable used to manipulate the viewing bounds of a GMSMapView object.
    private var _camera = GMSCameraPosition.camera(withLatitude: 0.0, longitude: 0.0, zoom: 6.0)
    /// GMSMapView where all geo-spatial data is drawn.
    private var _mapView: GMSMapView!
    /// Flag that alerts the CLLocationManager to stop trying to update the _mapView to show user's current location, set to true once the user has touched the _mapView.
    private var _shouldSuspendLocationUpdates  = false
    /// Flag to keep track of the state of the sideMenu.
    private var _sideMenuIsOnsceen  = false
    /// Flag to keep the app from continually showing the warning about location services being turned off.
    private var _hasShownAlertForLocationServices = false
    /// Array of GMSMarkers currently on _mapView.
    private var _markers : [GMSMarker] = []
    /// The place where the encoded polyline points string is stored before being imposed on _mapView.
    private var _encodedPointsString : String = ""
    /// CLLocation object representing SF.
    private let _sfLocation = CLLocation.init(latitude: 37.7749, longitude: -122.4194)
    /// CLLocation object representing Los Angeles.
    private let _losAngelesLocation = CLLocation.init(latitude: 34.0385, longitude: -118.3076)
    /// CLLocation object representing San Luis Obispo.
    private let _sanLuisObispoLocation = CLLocation.init(latitude: 35.28105, longitude: -120.66073)

    
    /// Type aliases to more clearly show how the JSON parsing is being done.
    private typealias PayloadDict = [String: AnyObject]
    private typealias PayloadArray = [AnyObject]

    // MARK: - Overridden functions from UIViewController.
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
    
    // MARK: - Setup methods
    
    /// Function that initializes the Google Map Services object with an API key retieved from a local config file(configuration.plist). A camera position is applied and the MapViewController's view is set to an instance of the GMSMapView Class.
    private func setupMap()  {
        GMSServices.provideAPIKey(self.getConfigDictionary()!["googleMapsAPIKey"] as! String)
        _camera = GMSCameraPosition.camera(withLatitude: _sfLocation.coordinate.latitude, longitude: _sfLocation.coordinate.longitude, zoom: 6.0)
        _mapView = GMSMapView.map(withFrame: view.frame, camera: _camera)
        _mapView.isMyLocationEnabled = true
        _mapView.delegate = self
        view = _mapView
        view.addSubview(_sideMenu)
    }
    
    /// Function that sets up the Core Location CLLocationManager instance and configures it so that this app and this class will receive updates about changes in the user's location.
    private func setupGPS()  {
        _locationManager.delegate = self
        _locationManager.distanceFilter = kCLDistanceFilterNone
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.requestWhenInUseAuthorization()
        _locationManager.startUpdatingLocation()
    }
    
    /// Function that configures this View Controller's parenting Navigation Controller to display a title as well as creating and adding a 'Menu' button that the user may interact with. Also changes NavCOntroller's title Font.
    private func setupNavigationController()  {
        title = "iCars Test"
        let menuButton = UIBarButtonItem.init(title:"Menu", style:.plain, target: self, action:#selector(menuButtonPressed))
        navigationItem.leftBarButtonItem = menuButton
        if let navFont = UIFont(name: "HelveticaNeue-Light", size: 17.0) {
            let navBarAttributesDictionary: [String: AnyObject]? = [
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: navFont]
            navigationController?.navigationBar.titleTextAttributes = navBarAttributesDictionary
        }
    }
    
    /// This method creates and assigns the blur effect to the _sideMenu UIView.
    private func stylizeSideMenu() {
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
    
    // MARK: - Helper functions
    /// Retrieves the configuration dictionary from the main app bundle. The caller of this function is responsible for extracting individual values from the returned Dictionary. If there is no config dictionary an optional containing a nil value is returned.
    private func getConfigDictionary() -> [String : AnyObject]? {
        let path = Bundle.main.path(forResource: "configuration", ofType: "plist")
        if let dict = NSDictionary(contentsOfFile: path!) as? [String : AnyObject] {
            return dict } else { return nil }
    }
    
    /// This method tests to see if the user has enabled Location Services for this app and if not warns and requests that the user turn on the service in the settings app.
    private func testForLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined, .restricted, .denied:
                let alert = UIAlertController(title: "Location Services Needed", message: "This app works best with location services to be turned on. Please modify your settings to fully utilize this app. Settings->Privacy->LocationServices", preferredStyle: .alert)
                let continueAction = UIAlertAction(title: "Continue without location", style: .default) { (result : UIAlertAction) -> Void in
                    print("Continue without access")
                }
                let settingsAction = UIAlertAction(title: "Change settings", style: .cancel) { (result : UIAlertAction) -> Void in
                    UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
                }
                alert.addAction(continueAction)
                alert.addAction(settingsAction)
                self.present(alert, animated: true, completion: nil)
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access")
            }
        } else {
            print("Location services are not enabled")
        }
    }
 
    // MARK: - Mapview helper methods
    
    ///Convienence method for updating the _camera's viewable area based on the latitude and longitude parameters
    /// - Parameter latitude: A latitude in Double format used to orient the _camera along a vertical axis
    /// - Parameter longitude: A longitude in Double format used to orient the _camera along a horizontal axis
    /// - Parameter zoom: A Float used to determine how much of the map is shown on screen
    private func updateMapViewToLocation(latitude: Double, longitude: Double, zoom: Float?) {
        if let zoomToSet = zoom  {
            _camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom:zoomToSet)
        }
        else {
        _camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: _mapView.camera.zoom)
        }
        _mapView.camera = _camera
    }
    /// Places a GMSMarker on the _mapview for San Francisco
    private func placeSFMarker() {
        placeMarkerOnMapfor(latitude: _sfLocation.coordinate.latitude, longitude: _sfLocation.coordinate.longitude, title: "San Francisco", snippet: "United States")
    }
    /// Places a GMSMarker on the _mapview for New York
    private func placeNYMarker() {
        placeMarkerOnMapfor(latitude: _losAngelesLocation.coordinate.latitude, longitude: _losAngelesLocation.coordinate.longitude, title: "New York City", snippet: "United States")
    }
    private func placeSLOMarker() {
        placeMarkerOnMapfor(latitude: _sanLuisObispoLocation.coordinate.latitude, longitude: _sanLuisObispoLocation.coordinate.longitude, title: "San Luis Obispo", snippet: "United States")
    }
    /// convienence method for placing GMSMarkers on the _mapView
    /// - Parameter latitude: A latitude in Double format used to place GMSMarker.
    /// - Parameter longitude: A longitude in Double format used to place GMSMarker.
    /// - Parameter title: String to descibe the GMSMarkers marked location.
    /// - Parameter snippet: String to further descibe the GMSMarkers marked location.
    private func placeMarkerOnMapfor(latitude: Double, longitude: Double, title: String?, snippet: String?) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude:latitude, longitude: longitude)
        if let titleString = title {
            marker.title = titleString
        }
        if let snippetString = snippet {
            marker.snippet = snippetString
        }
        marker.map = _mapView
        _markers.append(marker)
    }
    /// Draws the polyline from SF to NY based on the member property '_encodedPointsString' which is set when we receive a response from the google directions API and parsed out of the JSON response. The drawing is done on the main thread as required by the Google Maps iOS API.
    private func drawPolyline() {
        DispatchQueue.main.async {
            if let path = GMSPath(fromEncodedPath: self._encodedPointsString) {
                let routeLine = GMSPolyline(path: path)
                routeLine.strokeWidth = 7
                routeLine.strokeColor = UIColor.init(colorLiteralRed: 0.039, green: 0.376, blue: 0.996, alpha: 1.0)
                routeLine.map = self._mapView
                self.showAllMarkersOnMapFor(path: path)
            }
        }
    }
    /// Method to frame all points on _mapView within the camera's bounds. Must be performed on main thread per Google Maps iOS API.
    /// - Parameter path: A GMSPath that the camera and _mapView will frame.
    private func showAllMarkersOnMapFor(path: GMSPath) {
        let bounds = GMSCoordinateBounds.init(path: path)
        DispatchQueue.main.async {
            self.placeNYMarker()
            self.placeSFMarker()
            self.placeSLOMarker()
            self._mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 50.0))
        }
    }
    
    // MARK: - Menu Button related methods
    /// Action triggered when the user presses the 'Menu' button located inside the navigation controller's navigation bar.
    internal func menuButtonPressed() {
        toggleSideMenuOnScreen()
    }
    
    /// Adjusts _sideMenu's frame to an appropriate one based on device screen size.
    private func adjustSideMenuForParentsCurrentFrame() {
        _sideMenu.frame = CGRect(x: (_sideMenu.frame.size.width * -1.0), y: (view.frame.height * 0.08), width: _sideMenu.frame.width, height: _sideMenu.frame.height)
    }
    
    /// Method to show/hide _sideMenu based on the current state of the _sideMenu.
    private func toggleSideMenuOnScreen() {
        let distanceMultiplier : CGFloat = 0.45
        if _sideMenuIsOnsceen {
            // move sideMenu Off-screen
            UIView.beginAnimations(nil, context: nil)
            _sideMenu.center = CGPoint(x: (_sideMenu.center.x - (view.frame.size.width * distanceMultiplier)), y: _sideMenu.center.y)
            UIView.commitAnimations()
            _sideMenuIsOnsceen = false
        } else {
            // move sideMenu On-screen
            UIView.beginAnimations(nil, context: nil)
            _sideMenu.center = CGPoint(x: (_sideMenu.center.x + (view.frame.size.width * distanceMultiplier)), y: _sideMenu.center.y)
            UIView.commitAnimations()
            _sideMenuIsOnsceen = true
        }
    }
    
    /// IBAction triggered when the "New York" button is tapped in the _sideMenu, this method centers the map around the New York City Lat Long.
    @IBAction private func newYorkButtonPressed(_ sender: AnyObject) {
        toggleSideMenuOnScreen()
        _mapView.clear()
        _shouldSuspendLocationUpdates = true
        updateMapViewToLocation(latitude: _losAngelesLocation.coordinate.latitude, longitude:_losAngelesLocation.coordinate.longitude, zoom:Float(6.0))
        placeNYMarker()
    }
    
    /// IBAction triggered when the "San Francicso" button is tapped in the _sideMenu, this method centers the map around the San Francicso Lat Long.
    @IBAction private func SFButtonPressed(_ sender: AnyObject) {
        //37.7749° N, 122.4194° W
        toggleSideMenuOnScreen()
        _mapView.clear()
        _shouldSuspendLocationUpdates = true
        placeSFMarker()
        updateMapViewToLocation(latitude: _sfLocation.coordinate.latitude, longitude:_sfLocation.coordinate.longitude, zoom:Float(6.0))
    }
    
    /// IBAction triggered when the "SF to NY" button is tapped in the _sideMenu, this method triggers the network call to the google directions API, which ultimately results in the drawing of the directions polyline on the _mapView as well as the _mapView being reframed to show the entire route and the to and from waypoints.
    @IBAction private func SFToNYButtonPressed(_ sender: AnyObject) {
        _shouldSuspendLocationUpdates = true
        _mapView.clear()
        toggleSideMenuOnScreen()
        requestDirections(from: CLLocation.init(latitude: _sfLocation.coordinate.latitude , longitude: _sfLocation.coordinate.longitude), to: CLLocation.init(latitude: _losAngelesLocation.coordinate.latitude, longitude: _losAngelesLocation.coordinate.longitude))
    }

    // MARK: - Google Directions API Query method
    /// This method uses the TMINetwork manager class to make an API request from the Google Directions API. Specifically this method sets up the URL request, sets headers for the network manager and also creates the 'dataTask' ultimately responsible for retrieving the results of the query.
    private func requestDirections(from:CLLocation, to:CLLocation)  {
        let headers : [String: String] =   ["device-token"      : "abc123",
                                            "accept-language"   : "en",
                                            "client-name"       : "ios",
                                            "Accept"            : "application/json"]
        
        let apiKey = self.getConfigDictionary()!["googleDirectionsAPIKey"] as! String
        
        let networkManager = TMINetworkManager.init(withHeaders: headers, andDelegate: self)
        networkManager.addDataTaskToSession(withURLString:
            "https://maps.googleapis.com/maps/api/directions/json?origin=\(from.coordinate.latitude),\(from.coordinate.longitude)&destination=\(to.coordinate.latitude),\(to.coordinate.longitude)&waypoints=\(_sanLuisObispoLocation.coordinate.latitude),\(_sanLuisObispoLocation.coordinate.longitude)&key=\(apiKey)")
        
    }

    // MARK: - TMINetworkManager Delegate methods
    /// TMINetworkManager Delegate method, called when the networkManager has recieved data from the queried server.
    func didFinishNetworkCall(withResults results: Data, fromManager manager: TMINetworkManager) {
        do {
            let json = try JSONSerialization.jsonObject(with: results as Data, options: .allowFragments) as! PayloadDict
            guard let routes = json["routes"] as! PayloadArray!,
                let route = routes[0] as? PayloadDict,
                let overviewPolyline = route["overview_polyline"] as? PayloadDict,
                let points = overviewPolyline["points"] as? String else { return }
            _encodedPointsString = points
            drawPolyline()
        } catch let error  {
            print("JSON error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !_shouldSuspendLocationUpdates {
            updateMapViewToLocation(latitude: locations[0].coordinate.latitude , longitude: locations[0].coordinate.longitude, zoom:nil)
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if !_hasShownAlertForLocationServices {
            testForLocationServices()
            _hasShownAlertForLocationServices = true
        }
        print("location error")
    }
    
    // MARK: - GMSMapVIew Delegate methods
    /// GMSMapView delegate method: used to disable location updating when the user takes over control of map
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        _shouldSuspendLocationUpdates = true
        if _sideMenuIsOnsceen {
            toggleSideMenuOnScreen()
        }
    }
    
    //take gmspath created from encoded return value
    // use segmentsForLength method to get the segment approx. 100 miles away
    // use coordinateAtIndex: method on mutablePath to get CLLocationCoordinate2D
    
}
