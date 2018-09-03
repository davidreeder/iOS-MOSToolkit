mobilesound (v0.8)
======================

Swift and Objective-C classes, categories and extensions for production, logging and debugging.  
Core Objective-C classes complemented by Specta tests.



---
## Swift Highlights

### swift/classes/DeviceMotion

Encapsulate and manage CMMotionManager with a single class.
Provides raw and normalized data.


### swift/classes/Log

Simple class for logging in situ.




---
## Objective-C Highlights

### objective-c/classes/MOSTGMindwave 

Provide raw and normalized data from NeuroSky Mindwave. 



### objective-c/classes/MOSNTPClock

Encapsulate and manage ios-ntp with a single class.

For more details, see https://github.com/davidreeder/ios-ntp .



### objective-c/classes/MOSDatafileCache 

Simple file caching.  

* Discards least recently used (LRU), or blocks additions when cache is full.
* Set directory location and cache size upon initialization.
* Persists across application executions.
* Sanity checks for corrupted contents.



### objective-c/classes/MOSPropertyList 

Unified management of property lists.  

* Always returns requested type.
* Store in files or User Defaults.  
* User Defaults dictionary isolated under a single root key; multiple keys may co-exist.
* Set file location upon initialization, or rely on sequestered default directory and/or default file.
* Copy active property list to URL.



### objective-c/classes/specta/MOSTestSandbox

Reusable, disposable filesystem sandbox for automated testing.

Runs on device or within Simulator.

