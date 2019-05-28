
"Header" Files for Exisiting Core Swift Files
=============================================
> Documented by Jack Kasbeer
>
> Created: May 27, 2019


Table of Contents:
------------------
1. AppDelegte.swift
2. ViewController.swift
3. DestinationViewController.swift
4. GoogleSearch.swift
5. CosmosDistrib.swift
6. Helper.swift
7. Reachability.swift
8. LocationView.swift
9. DetailView.swift
10. Extra/Other


Shake Main Swift Files
----------------------

### AppDeleGate.swift

**Dependencies:** 
1. UIKit
2. CoreLocation
3. Foundation
4. GoogleMaps

```swift
/*
 * AppDelegate.swift
 *
 *  The main swift file for managing application state transitions
 * 
 */

@UIApplicationMain internal class AppDelegate : UIResponder, 
							    UIApplicationDelegate, 
							    ClLocationManagerDelegate {
	//
	// VARS: - Attributes of the Class
	//

	internal var window: UIWindow?
	internal var locationManagert: CLLocationManager
	internal var status: CLAuthorizationStatus
	internal var userCoord: CLLocationCoordinate2D?
	internal var dest: CLLocationCoordinate2D?
	internal var angle: Double?
	internal var distFromDest: Double?

	internal func getApiKey() -> String

	internal func locationGetterSetup()
	
	//
	// MARK: - Location Manager Delegate Functions
	//

	internal func locationManager(_ manager: CLLocationManager,
						 didChangeAuthorization status: CLAuthorizationStatus)
	internal func locationManager(_ manager: CLLocationManager,
						 didUpdateLocations locations: [CLLocation])
	
	//
	// INCOMPLETE: - Error handing function for the LocMan
	//

	internal func locationManager(_ manager: CLLocationManager,
						 didFailWithError error: Error)

	// Method to incorporate compass feature (floating around 'bubble' location)
	internal func locationManager(_ manager: CLLocationManager,
						 didUpdateHeading newHeading: CLHeading)
	//
	// MARK: - Application Functions
	//

	internal func application(_ application: UIApplication,
					   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool
	internal func application(_ application: UIApplication, 
					   shouldRestoreApplicationState coder: NSCoder) -> Bool

	// Method to handle transitions from active to inactive state
	internal func applicationWillResignActive(_ application: UIApplication)

	// Method to release shared resources, ave user data, invalidate timers, 
	//  and store enough application state info to restore your application 
	//  to its current state in case it is terminated
	internal func applicationDidEnterBackground(_ application: UIApplication)
	
	// Method that's called as part of transition from background to inactive state
	//  -> use this method to undo many changes made on entering the background
	internal func applicationWillEnterForeground(_ application: UIApplication)
	
	// Method to restart tasks that were paused (or not yet started) while
	//  the application was inactive
	internal func applicationDidBecomeActive(_ application: UIApplication)
	
	// Called if the application is about to terminate
	//  Note: - save changes in the applications managed object context
	//          before the application terminates (`self.saveContext()`)
	internal func applicationWillTerminate(_ application: UIApplication)
	internal func applicationDidReceiveMemoryWarning(_ application: UIApplication)
}

extension UIViewController {
	
	internal func topMostViewController() -> UIViewController
}

extension UIApplication {

	internal func topMostViewController() -> UIViewController?
}
```


### ViewController.swift

**Dependencies:**
1. Foundation
2. UIKit
3. CoreLocation

```swift
/*
 * ViewController.swift
 *
 *  ViewController corresponds to the initial view controller
 *  User can select a nearby location they would like to query
 *  a response is retrieved from a call to Google Places API Web Service
 *
 */

internal protocol ViewControllerDelegate : AnyObject {

	function transferDataFrom(viewController: ViewController)
}

internal class ViewController : UIViewController {
	
	//
	// VARS: attributes of the class
	//

	@IBOutlet weak internal var shakeIcon: UIImageView!

	weak internal var delegate: ViewControllerDelegate?
	
	internal var results: [[String : NSObject]]
	internal var locationNames: [String]?
	internal var userCoord: CLLocationCoordinate2D?
	internal var string: String?
	internal var animateSplash: Bool
	
	// Method to resolve internet connectivity issues when user leaves
	//  and then later returns to the app
	internal func applicationWillEnterForeground(_ notification: Notification)
	
	// Execute the Google Places API call
	//  Note: - currently only based on PRESET VALUES (e.g. CoinFlip & atms)
	internal func runQuery()
	
	// Method to receive the JSON data:
	//  Successful http response => parse location names,
	//  Failed http response => raise error
	internal func responseHandler(data: Data?)
	
	//
	// MARK: - override functions in `UIViewController`
	//

	override internal func viewDidLoad()
	override internal var preferredStatusBarStyle: UIStatusBarStyle { get }
	override internal func viewWillAppear(_ animated: Bool)
	
	// Method to send necessary data to destination controller
	override internal func prepare(for segue: UIStoryboardSegue, 
						sender: Any?)

}
```


### DestinationViewController.swift

**Dependencies:**
1. Foundation
2. UIKit
3. CoreLocation

```swift
// TODO: - interacting with Location is buggy (guest recognizer interference)

internal enum Redirect { 

	case Call, Map, Web 
}

/*
 *  DestinationViewController is the detail view controller
 *  It displays a Location object, shows the user how far away the location is,
 *  and where the user is relative to the location.
 *  Information is displayed in the Location object and more details on
 *  the location can be requested by tapping the Location object.
 *  Slide the DetailView up or down to enter full-screen or dismiss respectively.
 *  DetailView can scroll if expanded in which case the user can drag down %40
 *  of the screen to dismiss.
 *
 */

internal class DestinationViewController: UIViewController, 
					  	     DualViewDelegate,
					  	     DetailViewDelegate,
					  	     LocationViewDelegate,
					  	     ViewControllerDelegate {
	//
	// VARS: properties of the class
	//

	internal var shakeNum: Int
	internal var userLocation: CLLocation?
	internal var locationNames:[String?]?
	internal var results: Array<[String : NSObject]>?
	internal var userCoords: CLLocationCoordinate2D? { get set }
	internal var resultDetail: Array<[String : NSObject]>?
	internal var distanceLabel: UILabel?
	internal var addressLabel: UILabel?
	internal var compass: UIImageView?
	internal var locationView: Location?
	internal var detailView: DetailView?
	internal var detailShouldDisplay: Bool { get set }
	

	// ViewControllerDelegate routine used to initialize values
	internal func transferDataFrom(viewController: ViewController)

	//
	// MARK: - private functions unseen by interface 
	//
	// Compass initializer
	private func initCompass()
	
	// Detail view initializer
	private func initDetailView()
	
	// Address and distance label initializer
	private func initDescriptionViews()

	// Initializes an alert controller giving user redirect options;
	//  'type': where user would like to be redirected
	private func initRedirectAlertController(type: Redirect)
	
	// Clears location data so the object is reused instead of reinitialized
	private func clearObjectData()
	
	// Queries location details by making API request
	//  'atIndex': index of results array to access for relevant info
	private func retrieveJSON(atIndex: Int)
	
	// Response handler for api call which updates ui components with response
	//  details if successful; presents alerts signaling errors o.t.w.
	//  'data': JSON data in the form of bytes from response
	private func responseHandler(data: Data?)
	
	//
	// MARK: - override functions
	//
	// Method to set background img, init locationView object, 
	//  load first result of query, and init compass & location manager
	override internal func viewDidLoad()
	override internal var preferredStatusBarStyle: UIStatusBarStyle { get }
	
	// Method to detect "shake" and adjust the view accordingly
	//  Does nothing if the view isn't loaded
	override internal func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?)
	override internal func viewWillDisappear(_ animated: Bool)
	
	//
	// MARK: - @objc attribute functions
	//
	// #SELECTOR: - Method for swipe gesture action dismissing view controller
	@objc internal func unwindFromDetailVC(_ sender: UISwipeGestureRecognizer)

	// #SELECTOR: - Method manages the detail display
	@objc internal func unwindFromDetailVC(_ sender: UIGestureRecognizer)
	
	// #SELECTOR: - Method for long-pressed location 'bubble' button
	@objc internal func userHasTapped(_ sender: UIGestureRecognizer)
	
	//
	// MARK: - user-defined functions
	//
	// Method to notify location manager that user needs location updates
	internal func locationManagerSetup()
	
	// Method to update distance in real-time through AppDelegate
	internal func updateDistance(_ manager: CLLocationManager, destination: CLLocation)
	
	//
	// MARK: - LocationViewDelegate
	//
	internal func longPressAction(_ view: Location, sender: UIGestureRecognizer)
	internal func updateView(_ view: Location)
	internal func haltLocationUpdates()
	
	// 
	// MARK: - DuelViewDelegate
	//
	internal func navigationAction()
	internal func callLocationAction()
	
	//
	// MARK: - DetailViewDelegate
	//
	internal func redirectToCall()
	internal func redirectToMaps()
	internal func redirectToWeb()

	// TODO: not yet implemented
	internal func saveLocation()
	internal func remove(detailView: DetailView)
}
```
	
### GoogleSearch.swift

**Dependencies:**
1. Foundation

```swift
// To easily differentiate which API service is used
internal enum SearchType {

	case NEARBY
	case CUSTOM
	case DETAIL
	case PHOTO
}

// Search parameters to append to request URL
internal typealias Parameters = [String : String]

/*
 *  Struct containing a wrapper for Google Api requests.
 *  URL for request created at initialization time based on SearchType and Parameters
 *
 */
public struct GoogleSearch {

	internal var type: SearchType?
	internal var params: Parameters?
	internal var url: String?
	internal init(type: SearchType,	
			 parameters: Parameters?)
	
	private var nearbyURL: String = ...
	private var detailURL: String = ...
	private var photoURL: String = ...

	// Helper function used to append search param's to URL
	private mutating func appendParametersToURL()
	
	/*
     *  Creates a task that retrieves the contents of the call to the
     *  Google API specified by the url created based on search type.
     *
     *  @parameter session: api for downloading content (minimum requirements)
     *  @parameter handler: method, specified by controller that initiated
     *    search struct used, to manipulate data retrieved upon task completion
     */
	mutating internal func makeRequest(_ session: URLSession,
							handler: @escaping (Data?) -> Void)
	
	// Method to handle special use case: 
	//  If an http request must be made to a custom url,
	//  this function must be called before making request if search type is .custom
    mutating internal func setCustomURL(_ url: String?)
}
```

### CosmosDistrib.swift

*Skipping this file for now since it is not anything written by Tony or me.*

##### It covers code related to the "rating" aspect of each location.


### Helper.swift

*Skipping to save room in this document.*

##### Generally, this document covers varies class extensions and helper structs related to GoogleMaps, stylizing, alert messages, datatypes, etc.


### Reachability.swift

*A simple struct to determine network connectivity*

**Dependencies:**
1. Foundation
2. SystemConfiguration

```swift
public struct Reachability {

	internal static func isConnected() -> Bool
}
```

### LocationView.swift

**Dependencies:**
1. Foundation
2. UIKit
3. CoreLocation

```swift
/*  MARK: -  Protocol LocationViewDelegate
 *
 *  conforming class: DestinationViewController
 *  Establishes communication between Location object
 *  and DestinationViewController (delegation of tasks)
 *
 */
internal protocol LocationViewDelegate : AnyObject {

	func longPressAction(_ view: Location, sender: UIGestureRecognizer?)
	func updateView(_ view: Location)
	func haltLocationUpdates()
}

/*  MARK: - UIView Location
 *
 *  Location object built using interface builder.
 *  Displays information retrieved from NSDictionary (response from google api)
 *  if information requested exists.
 *
 */
internal class Location : UIView, DetailViewDataSource {

	internal var view: UIView!

	// Initialized when user long-taps
	internal var dualView: DualView?

	// Delegates tasks to DestinationViewController
	weak internal var delegate: LocationViewDelegate?

	@IBOutlet weak internal var image: UIImageView!
	@IBOutlet weak internal var ratingView: UIView!
	@IBOutlet weak internal var infoView: UIView!
	@IBOutlet weak internal var name: UILabel!
	@IBOutlet weak internal var cost: UILabel!

	internal enum State {

		case 'default'
		case pressed
	}

	internal var state: State { get set }

	// JSON object as Dictionary
	internal var rawData: [String : AnyObject]? { get set }

	internal var coordinates: (Double, Double)? { get set }
	internal var phoneNumber: String?
	internal var address: String?
	internal var formatAddress: String?
	internal var isOpen: Bool
	internal var reviews: NSArray?
	internal var weeklyHours: Array<String>?
	internal var openPeriods: Array<[String : AnyObject]>?
	internal var types: Array<String>?
	internal var mainType: String?
	internal var website: String?
	
	//
	// MARK: - methods used for proper initialization of Location object
	//
	override internal init(frame: CGRect)
	required internal init?(coder aDecoder: NSCoder)
	private func nibSetup()
	private func loadViewFromNib() -> UIView

	//
	// MARK: - methods used to retrieve information from JSON as a Dictionary
	//
	// Retrieve coordinates used for compass in DestinationViewController
	//  in conjuction with location updates
	private func getCoords() -> (Double, Double)?
	private func getName() -> String?

	// Updates Location object based on whether or not location is open
	private func openRn()
	private func setSchemeForUnavailableTimes()
	
	//
	// MARK: - getter & setting functions for Location data
	//
	// INCOMLPETE: - Retrieves location photos, but only displays one on Location object
	private func getPhoto()
	private func responseHandler(data: Data?)
	private func getPhoneNum() -> String?
	private func setPriceLvl()
	private func setRating()
	private func getAddress() -> String?
	private func setReviews()
	private func getHours()
	private func getWebsite()
	private func getTypes()

	// INCOMPLETE: - basic displacement of Location object in a repeated
	//				 animation (mimicking a "shake")
	private func shakeAnimation()

	// Switch used by self and delegate
	internal func toggleState()

	// Adds a preview of the location over a DualView that is animated 
	//  underneath
	internal func addPreviewToSubview()

	//
	// MARK: - methods used by the delegate (DestinationViewController)
	//

	internal func requestViewUpdate()
	@objc internal func longTap(_ sender: UIGestureRecognizer?)
	internal func stopLocationUpdates()
	internal func didstanceFromLocation(_ location: CLLocation) -> String

	//
	// MARK: - DetailViewDataSource
	//
	// Retrieves all necessary availability items
	internal func setHoursFor(detailView: DetailView)

	// Retrieves the following: Name, Open/Closed, Address, Types,
	//  Phone Number, Number of Reviews, and Website
	internal func setInfoFor(detailView: DetailView)

	// Sets the rating on DetailView
	internal func setRatingFor(detailView: DetailView)

	// Retrieves reviews and initializes them within expandedReviewView
	//  in ReviewView objects
	internal func setReviewsFor(detailView: DetailView)
}

/*  MARK: -  Protocol DualViewDelegate
 *
 *  conforming class: DestinationViewController
 *  Establishes communication between DualView object
 *  and DestinationViewVontroller (delegation of tasks)
 *
 */
internal protocol DualViewDelegate : AnyObject {

	func navigationAction()
	func callLocationAction()
}

/*  MARK: -  UIView DualView
 *  
 *  Initializes over Location object when long press is recognized
 *  within bounds of Location object. Contains an image of location
 *  as well as two buttons for navigation and phone call
 *
 */
internal class DualView : UIView {

	internal var rhs: UIView?
	internal var rhs_icon: UIImageView?
	internal var lhs: UIView?
	internal var lhs_icon: UIImageView?

	weak internal var delegate: DualViewDelegate?

	@objc internal func userHasTapped(_ sender: UIGestureRecognizer)

	override internal init(frame: CGRect)

	required internal init?(coder aDecoder: NSCoder)

	//
	// MARK: - private functions
	//

	fileprivate func setupViews(_ frame: CGRect)
	fileprivate func setupViewIcons(_ frame: CGRect)
}
```


### DetailView.swift

**Dependencies:**
1. Foundation
2. UIKit


```swift
// Identifier for detail subviews
internal class InfoView : UIView

// Identifier for reviews container
internal class ReviewsContainerView : InfoView

internal class WeeklyHoursLabel : UIView {

	internal var day1: UILabel?
	internal var day2: UILabel?
	internal var day3: UILabel?
	internal var day4: UILabel?
	internal var day5: UILabel?
	internal var day6: UILabel?
	internal var day7: UILabel?
	internal var monTimes: UILabel?
	internal var tueTimes: UILabel?
	internal var wedTimes: UILabel?
	internal var thuTimes: UILabel?
	internal var friTimes: UILabel?
	internal var satTimes: UILabel?
	internal var sunTimes: UILabel?

	internal var times: [String]? { get set }
	internal var rawData: [String]? { get set }

	//
	// MARK: - View initialization
	//

	override internal init(frame: CGRect)
	required internal init?(coder aDecoder: NSCoder)
	private func initDayLabels()
	private func initHoursLabels()
	private func removeWeekdayTextFrom(strings: [String]) -> [String]
	private func loadTimes()
}

//
// MARK: - identifier for custom scroll view
//

internal class SVCustom : UIScrollView {
	
	internal var fillColor: CGColor
	internal init(frame: CGRect, color: CGColor)
	required internal init?(coder aDecoder: NSCoder)
	override internal func draw(_ rect: CGRect)
}

//
// MARK: - DetailView main source
//

internal protocol DetailViewDelegate : AnyObject {
	
	func redirectToCall()
	func redirectToWeb()
	func redirectToMaps()
	func saveLocation()
	func remove(detailView: DetailView)
}

internal protocol DetailViewDataSource: AnyObject {

	func setHoursFor(detailView: DetailView)
	func setInfoFor(detailView: DetailView)
	func setRatingFor(detailView: DetailView)
	func setReviewsFor(detailView: DetailView)
}

internal class DetailView : UIView, UIScrollViewDelegate {

	weak internal var delegate: DetailViewDelegate?
	weak internal var datasource: DetailViewDataSource?

	internal var scrollView: SVCustom!
	
	// Dimensions
	internal var svHeight: CGFloat!
	internal var svWidth: CGFloat!
	internal var gHeight: CGFloat!
	internal var iHeight: CGFloat!

	// Views
	internal var isOpenView: InfoView!
	internal var addressView: InfoView!
	internal var hoursView: InfoView!
	internal var expandedHoursView: InfoView!
	internal var callView: InfoView!
	internal var saveView: InfoView!
	internal var reviewView: InfoView!
	internal var expandedReviewView: ReviewsContainerView!
	internal var ratingView: UIView!
	internal var openIcon: UIImageView!
	
	// Labels
	internal var weeklyHoursLabel: WeeklyHoursLabel!
	internal var exColHours: UIButton!
	internal var exColReviews: UIButton!
	internal var addressLabel: UILabel!
	internal var nameLabel: UILabel!
	internal var typeLabel: UILabel!
	internal var isOpenLabel: UILabel!
	internal var numberLabel: UILabel!
	internal var saveLabel: UILabel!
	internal var reviewsLabel: UILabel!
	internal var webIconLabel: UILabel!

	// Buttons
	internal var addressIcon: UIButton!
	internal var callIcon: UIButton!
	internal var saveIcon: UIButton!
	internal var webIcon: UIButton!
	
	// Other
	internal var rating: Double
	internal var svExpectedHeight: CGFloat
	internal var hoursArray: [String]?
	internal var reviews: NSArray?
	internal var website: String?
	internal var isOpen: Bool?
	internal var hoursAvailable: Bool
	internal var hoursExpanded: Bool
	internal var reviewsExpanded: Bool
	internal var isFullScreen: Bool
	internal var svHeaderColor: UIColor?

	internal init(dframe: CGRect, svframe: CGRect, open: Bool?)
	required internal init?(coder aDecoder: NSCoder)

	internal func loadData()

	@objc internal func removeView(_ sender: UISwipeGestureRecognizer)
	@objc internal func adjustScrollView(_ sender: UISwipeGestureRecognizer)
	@objc internal func handleWebIconTapped(_ sender: UIButton)
	@objc internal func handleLocationIconTapped(_ sender: UIButton)
	@objc internal func exColHoursAction(_ sender: UITapGestureRecognizer)
	@objc internal func handleCallIconTapped(_ sender: UIButton)
	@objc internal func saveIconTapped(_ sender: UIButton)
	@objc internal func exColRevAction(_ sender: UITapGestureRecognizer)

	internal func scrollViewDidScroll(_ scrollView: UIScrollView)
}

internal class ReviewView: UIView {

	internal var label: UILabel!
	internal var nameLabel: UILabel!
	internal var ratingLabel: UILabel!
	internal var starView: CosmosView!
	internal var imageView: UIImageView!
	internal var ratingView: UIView!

	internal init(frame: CGRect, rawData: [String : AnyObject]?)
	required internal init?(coder aDecoder: NSCoder)
}
```





































