import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

       // 👇 initialize Google Maps with the API key
    GMSServices.provideAPIKey("AIzaSyD0isLXBTFihTM-hEI9pCaxiAdL04Vo2Rg")
    

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
   
    


  }
}
