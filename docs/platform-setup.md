# Platform setup
Generate platform files with flutter create --platforms=android,ios,web --org kz.mihrab --project-name mihrab .
Android: add ACCESS_FINE_LOCATION and ACCESS_COARSE_LOCATION to the manifest.
iOS: add NSLocationWhenInUseUsageDescription to Info.plist. Configure geolocator BYPASS_PERMISSION_LOCATION_ALWAYS=1 for CocoaPods if applicable.
Web: geolocation requires localhost or HTTPS; compass is static.
GPS coordinates remain in memory and are requested on demand. Prayer schedule uses the manually selected city. Magnetic declination correction and real-device testing are pending.
