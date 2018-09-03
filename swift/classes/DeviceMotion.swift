//
// DeviceMotion.swift
//
// Capture all device motion data at a high cycle rate 
// while generating a history of normalized measurements documenting position and speed 
// in a commonsense manner.
//
//
// TBD  How to calibrate and receive data from magnetometer?!
//
//
// CLASS DEPENDENCIES: 
//   Log, 
//   //LocationHeadingManager
//
// EXTENSION DEPENDENCIES:
//   //CMMagneticFieldCalibrationAccuracyExtension
//   DoubleExtension
//   UIDeviceOrientationExtension
//
// CATEGORY DEPENDENCIES:
//   UIDevice
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

import Foundation
import Darwin
import CoreMotion
import UIKit



//----------------------------------------------------------------------------- -o--
class DeviceMotion : CMMotionManager 
{
  static let  singleton = DeviceMotion()


  // MARK: - Public Properties.
  //

  var  attitude          = CMAttitude()                 // roll, pitch, yaw
  var  rotationRate      = CMRotationRate()             // x, y, z
  var  gravity           = CMAcceleration()             // x, y, z
  var  userAcceleration  = CMAcceleration()             // x, y, z
  //var  magneticField     = CMCalibratedMagneticField()  // (x, y, z) + (.Uncalibrated, .Low, .Medium, .High)  //TBD

  var  orientation : UIDeviceOrientation  { return self.device.orientation }

  var  proximityMonitoringEnabled : Bool  { return self.device.proximityMonitoringEnabled }
  var  proximityState             : Bool  { return self.device.proximityState }
            // NB  Does not work when status bar is not present?  Eg, when not showing in landscape mode.


  // Normalized, smoothed values.
  //

  var  nAttitudeRoll  : Double     { return self.normalizedValue(DM_KEY_ATTITUDE_ROLL) }
  var  nAttitudePitch : Double     { return self.normalizedValue(DM_KEY_ATTITUDE_PITCH) }
  var  nAttitudeYaw   : Double     { return self.normalizedValue(DM_KEY_ATTITUDE_YAW) }

  var  nRotationRateX : Double     { return self.normalizedValue(DM_KEY_ROTATION_RATE_X) }
  var  nRotationRateY : Double     { return self.normalizedValue(DM_KEY_ROTATION_RATE_Y) }
  var  nRotationRateZ : Double     { return self.normalizedValue(DM_KEY_ROTATION_RATE_Z) }

  var  nGravityX : Double          { return self.normalizedValue(DM_KEY_GRAVITY_X) }
  var  nGravityY : Double          { return self.normalizedValue(DM_KEY_GRAVITY_Y) }
  var  nGravityZ : Double          { return self.normalizedValue(DM_KEY_GRAVITY_Z) }

  var  nAccelerationX : Double     { return self.normalizedValue(DM_KEY_USER_ACCELERATION_X) }
  var  nAccelerationY : Double     { return self.normalizedValue(DM_KEY_USER_ACCELERATION_Y) }
  var  nAccelerationZ : Double     { return self.normalizedValue(DM_KEY_USER_ACCELERATION_Z) }



  // MARK: - Private Properties.
  //

  private var  captureIteration  = 0
  
  private let  device  = UIDevice.currentDevice()

  //private let  locationHeadingManager  = LocationHeadingManager()


  // Each Dictionary contains values derived from captureData(::) snapshot.
  //   
  private var  dataRecent                = [String : Double]()     // most recent values
  private var  dataRangeLow              = [String : Double]()     // lowest values 
  private var  dataRangeHigh             = [String : Double]()     // highest values

  private var  dataNormalized            = [String : Double]()     // recent value normalized to "common sense" range
  private var  dataNormalizedHysteresis  = [String : [Double]]()   // rolling average of last N normalization values



  // MARK: - Class Constants.
  //

  private let  DM_UPDATE_INTERVAL_IPHONE6_ONWARD   : NSTimeInterval  = (1.0 / 60.0)
  private let  DM_UPDATE_INTERVAL_PRIOR_TO_IPHONE6 : NSTimeInterval  = (1.0 / 10.0)
  //private let  DM_UPDATE_INTERVAL : NSTimeInterval  = (1.0 / 15.0)  //ALTERNATIVE
        // NB  Currently getting roughly 30Hz.


  private let  DM_HYSTERESIS_ARRAYSIZE_IPHONE6_ONWARD    = (30)
  private let  DM_HYSTERESIS_ARRAYSIZE_PRIOR_TO_IPHONE6  = (5)
  //private let  DM_HYSTERESIS_ARRAYSIZE  = (30 * 2)      //ALTERNATIVE
  //private let  DM_HYSTERESIS_ARRAYSIZE  = (15 * 3)      //ALTERNATIVE
        // TBD  Automatically calculate as function of captures/second?

  private var  DM_HYSTERESIS_ARRAYSIZE  = (-1)


  // Dictionary keys (and roots).
  //
  private let  DM_KEY_ATTITUDE        = "ATTITUDE"
  private let  DM_KEY_ATTITUDE_ROLL   = "ATTITUDE_ROLL"
  private let  DM_KEY_ATTITUDE_PITCH  = "ATTITUDE_PITCH"
  private let  DM_KEY_ATTITUDE_YAW    = "ATTITUDE_YAW"

  private let  DM_KEY_ROTATION_RATE    = "ROTATION_RATE"
  private let  DM_KEY_ROTATION_RATE_X  = "ROTATION_RATE_X"
  private let  DM_KEY_ROTATION_RATE_Y  = "ROTATION_RATE_Y"
  private let  DM_KEY_ROTATION_RATE_Z  = "ROTATION_RATE_Z"

  private let  DM_KEY_GRAVITY    = "GRAVITY"
  private let  DM_KEY_GRAVITY_X  = "GRAVITY_X"
  private let  DM_KEY_GRAVITY_Y  = "GRAVITY_Y"
  private let  DM_KEY_GRAVITY_Z  = "GRAVITY_Z"

  private let  DM_KEY_USER_ACCELERATION    = "USER_ACCELERATION"
  private let  DM_KEY_USER_ACCELERATION_X  = "USER_ACCELERATION_X"
  private let  DM_KEY_USER_ACCELERATION_Y  = "USER_ACCELERATION_Y"
  private let  DM_KEY_USER_ACCELERATION_Z  = "USER_ACCELERATION_Z"

#if false  //TBD
  private let  DM_KEY_MAGNETIC_FIELD    = "MAGNETIC_FIELD"
  private let  DM_KEY_MAGNETIC_FIELD_X  = "MAGNETIC_FIELD_X"
  private let  DM_KEY_MAGNETIC_FIELD_Y  = "MAGNETIC_FIELD_Y"
  private let  DM_KEY_MAGNETIC_FIELD_Z  = "MAGNETIC_FIELD_Z"

  private let  DM_KEY_MAGNETIC_ACCURACY  = "MAGNETIC_ACCURACY"
#endif


  // Relative maxima for each data category.
  // Defined categories may go over 100%.  Ideally "into the red" due to extra kinetic effort...
  //
  private let  DM_MAX_ATTITUDE           = M_PI;
  private let  DM_MAX_ROTATION_RATE      = 30.0
  private let  DM_MAX_GRAVITY            = 1.0
  private let  DM_MAX_USER_ACCELERATION  = 4.0
  //private let  DM_MAX_MAGNETIC_FIELD    = ???  //TBD




  //----------------------------------------------------------------------------- -o--
  // MARK: - Lifecycle.

  //-------------------------- -o-
  // XXX  Clearly lacking modelDetail cases, also...
  //      iPhone 5* may differentiate from iPhone 4*, likewise within each hardware version family...
  //
  override init()  
  {
    super.init()
    Log.mark(self, f:__FUNCTION__)


    //
    if !self.deviceMotionAvailable {
      Log.error(self, f:__FUNCTION__, msg:"CMDeviceMotion is NOT available.")
    }


    //
    self.showsDeviceMovementDisplay = true
            // TBD  How to force calibration screen, then remember the results throughout session...  (between sessions?)

    //
    switch  UIDevice.modelDetail()
    {
    case  "iPhone 4", "iPhone 4c", "iPhone 4s",
          "iPhone5", "iPhone 5c", "iPhone 5s":
      self.deviceMotionUpdateInterval  = DM_UPDATE_INTERVAL_PRIOR_TO_IPHONE6
      DM_HYSTERESIS_ARRAYSIZE          = DM_HYSTERESIS_ARRAYSIZE_PRIOR_TO_IPHONE6
      break

    default:
      self.deviceMotionUpdateInterval  = DM_UPDATE_INTERVAL_IPHONE6_ONWARD
      DM_HYSTERESIS_ARRAYSIZE          = DM_HYSTERESIS_ARRAYSIZE_IPHONE6_ONWARD
    }


    //
    self.device.proximityMonitoringEnabled = true

    if  !self.device.proximityMonitoringEnabled  {
      Log.warning(self, f:__FUNCTION__, msg:"COULD NOT enable proxmity monitoring.")
    }
  }



  //-------------------------- -o-
  deinit  { Log.mark(self, f:__FUNCTION__) }




  //----------------------------------------------------------------------------- -o--
  // MARK: - Public Methods.

  //-------------------------- -o-
  func  start()
  {
    Log.mark(self, f:__FUNCTION__)


    // TBD -- use CLLocationManager to coax out magnetometer data?
#if false
    let  authorizationStatus  = self.locationHeadingManager.authorizationStatus
    Log.info(self, f:__FUNCTION__, msg:"authorizationStatus=\( authorizationStatus.rawValue )")

    self.locationHeadingManager.start()  // TBD  NEED to guard against/check for low auth status?

    //self.startMagnetometerUpdates()
#endif


    //
    let  operationQueue  = NSOperationQueue.init()

    operationQueue.name = Log.signature(self, f:__FUNCTION__)

    if  #available(iOS 8, *)  {
      operationQueue.underlyingQueue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
    } 


    self.startDeviceMotionUpdatesToQueue(operationQueue, withHandler:
      {
        (dm:CMDeviceMotion?, error:NSError?) in self.captureData(deviceMotion:dm, error:error)
      })

  }  //start()


  //-------------------------- -o-
  // NB  DOES NOT clear data between sessions.
  //
  func  stop()
  {
    Log.mark(self, f:__FUNCTION__)

    self.stopDeviceMotionUpdates()

#if false  //TBD
    self.locationHeadingManager.stop()
    self.stopMagnetometerUpdates()
#endif
  }



  //-------------------------- -o-
  func  clearDataAll()  // UNUSED
  {
    Log.mark(self, f:__FUNCTION__)

    self.dataRecent = [:]
    self.clearDataHighsAndLows()
  }


  //-------------------------- -o-
  func  clearDataHighsAndLows()
  {
    Log.mark(self, f:__FUNCTION__)

    self.dataRangeLow              = [:]
    self.dataRangeHigh             = [:]
    self.dataNormalized            = [:]
    self.dataNormalizedHysteresis  = [:]
  }



  //-------------------------- -o-
  // TBD  Different form factor for iPhone4.  (And others prior to iPhone6...)
  //
  func  status(title: String = "") -> String
  {
    let  header  = self.description
    let  footer  = ""


    //
    var  body =  "orientation  \(String(self.device.orientation.description))\n"

    if  self.device.proximityMonitoringEnabled  {
      body +=    "proximity    \(self.device.proximityState)\n"
    }

    //
    body +=      "\n"
               + "attitude  (radians)\n"
               + "\t" +  self.stringForParameterField("roll ", field:DM_KEY_ATTITUDE_ROLL)   + "\n"
               + "\t" +  self.stringForParameterField("pitch", field:DM_KEY_ATTITUDE_PITCH)  + "\n"
               + "\t" +  self.stringForParameterField("yaw  ", field:DM_KEY_ATTITUDE_YAW)    + "\n"
    //
    body +=      "\n"
               + "rotation rate  (radians/sec)\n"
               + "\t" +  self.stringForParameterField("x    ", field:DM_KEY_ROTATION_RATE_X)  + "\n"
               + "\t" +  self.stringForParameterField("y    ", field:DM_KEY_ROTATION_RATE_Y)  + "\n"
               + "\t" +  self.stringForParameterField("z    ", field:DM_KEY_ROTATION_RATE_Z)  + "\n"
    //
    body +=      "\n"
               + "gravity  (gravitational force)\n"
               + "\t" +  self.stringForParameterField("x    ", field:DM_KEY_GRAVITY_X)  + "\n"
               + "\t" +  self.stringForParameterField("y    ", field:DM_KEY_GRAVITY_Y)  + "\n"
               + "\t" +  self.stringForParameterField("z    ", field:DM_KEY_GRAVITY_Z)  + "\n"
    //
    body +=      "\n"
               + "acceleration rate  (added grav. force)\n"
               + "\t" +  self.stringForParameterField("x    ", field:DM_KEY_USER_ACCELERATION_X)  + "\n"
               + "\t" +  self.stringForParameterField("y    ", field:DM_KEY_USER_ACCELERATION_Y)  + "\n"
               + "\t" +  self.stringForParameterField("z    ", field:DM_KEY_USER_ACCELERATION_Z)  + "\n"
    //
#if false
    body +=      "\n"
               + "magnetic field -- \( self.magneticField.accuracy.description )\n"
               + "\t" +  self.stringForParameterField("x    ", field:DM_KEY_MAGNETIC_FIELD_X)  + "\n"
               + "\t" +  self.stringForParameterField("y    ", field:DM_KEY_MAGNETIC_FIELD_Y)  + "\n"
               + "\t" +  self.stringForParameterField("z    ", field:DM_KEY_MAGNETIC_FIELD_Z)  + "\n"
#endif


    //
    return "\(header)\n\n\(body)\n\(footer)"

  }  //status(:)



  //-------------------------- -o-
  override var  description : String
    {
      let  description =    "CoreMotion\n"
                          + "    \(UIDevice.modelDetail())  \(self.device.systemVersion)  (\(self.device.name))\n"
                          + "    iteration    \(self.captureIteration)\n"

      return  description
    }


  //-------------------------- -o-
  func  dump(title: String = "")
  {
    var  dumpEverything =    title
                           + "\n\titeration\t\( self.captureIteration )"

                           + "\n\n\t\( self.attitude )"

                           + "\n\t\( self.rotationRate )"

                           + "\n\n\tgravity           \( self.gravity )"
                           +   "\n\tuserAcceleration  \( self.userAcceleration )"

                           + "\n\n\torientation\t\t\( self.device.orientation.description )"

    if  self.device.proximityMonitoringEnabled  {
      dumpEverything +=      "\n\tproximity\t\t\(self.device.proximityState)"
    }
                                              /* TBD
                           + "\n\n\t\( self.magneticField.field ) -- \( self.magneticField.accuracy.description )"
                           //+ "\n\n\t\( self.magnetometerData! )"
                                              */
    dumpEverything +=        "\n\n\n"


    //
    Log.info(self, f:__FUNCTION__, msg:dumpEverything)

    //Log.info(self, f:__FUNCTION__, msg:"self.dataRecent=\(self.dataRecent)")  //DEBUG
    //Log.info(self, f:__FUNCTION__, msg:"self.dataNormalizedHysteresis=\(self.dataNormalizedHysteresis)")  //DEBUG
    //Log.info(self, f:__FUNCTION__, msg:"self.dataNormalized=\(self.dataNormalized)")  //DEBUG

  }  //dump(:)




  //----------------------------------------------------------------------------- -o--
  // MARK: - Private Methods.
  
  //-------------------------- -o-
  private func  captureData(deviceMotion dm: CMDeviceMotion?, error: NSError?)
  {
    self.captureIteration += 1;

    Log.nsError(self, f:__FUNCTION__, error:error)
                  // XXX  Never received CMErrorDeviceRequiresMovement?  does it occur?  why doesn't it occur?

    //
    guard let  dmUW = dm  else  { return }

    self.attitude               = dmUW.attitude
    self.rotationRate           = dmUW.rotationRate
    self.gravity                = dmUW.gravity
    self.userAcceleration       = dmUW.userAcceleration
    //self.magneticField          = dmUW.magneticField		// TBD

    
    self.populateRecent()
    //self.dump("CAPTURE DATA")  //DEBUG

    self.populateRanges()

    self.normalizeRecent()

  }  //captureData(::)


  //-------------------------- -o-
  private func  populateRecent()
  {
    self.dataRecent = [
            DM_KEY_ATTITUDE_ROLL          : self.attitude.roll,
            DM_KEY_ATTITUDE_PITCH         : self.attitude.pitch,
            DM_KEY_ATTITUDE_YAW           : self.attitude.yaw,

            DM_KEY_ROTATION_RATE_X        : self.rotationRate.x,
            DM_KEY_ROTATION_RATE_Y        : self.rotationRate.y,
            DM_KEY_ROTATION_RATE_Z        : self.rotationRate.z,

            DM_KEY_GRAVITY_X              : self.gravity.x,
            DM_KEY_GRAVITY_Y              : self.gravity.y,
            DM_KEY_GRAVITY_Z              : self.gravity.z,

            DM_KEY_USER_ACCELERATION_X    : self.userAcceleration.x,
            DM_KEY_USER_ACCELERATION_Y    : self.userAcceleration.y,
            DM_KEY_USER_ACCELERATION_Z    : self.userAcceleration.z,

      			/* TBD
            DM_KEY_MAGNETIC_FIELD_X       : self.magneticField.field.x,
            DM_KEY_MAGNETIC_FIELD_Y       : self.magneticField.field.y,
            DM_KEY_MAGNETIC_FIELD_Z       : self.magneticField.field.z,

            DM_KEY_MAGNETIC_ACCURACY      : Double(self.magneticField.accuracy.rawValue)  // NB
			*/
          ]
  }


  //-------------------------- -o-
  private func  populateRanges()
  {
    for (key, value) in self.dataRecent
    {
      if  nil == self.dataRangeLow[key]
      {
        self.dataRangeLow[key]  = value
        self.dataRangeHigh[key] = value

      } else if  value < self.dataRangeLow[key]  {
        self.dataRangeLow[key] = value

      } else if  value > self.dataRangeHigh[key]  {
        self.dataRangeHigh[key] = value
      }
    }
  }


  //-------------------------- -o-
  // Normalize inputs:
  //   . Attitude across 2*PI,
  //   . abs(Rotation Rate) across DM_MAX_ROTATION_RATE  [30.0],
  //   . Gravity across 1.0 * 2,
  //   . abs(User Acceleration) across DM_MAX_USER_ACCELERATION  [4.0],
  //   . OTHERWISE... normalize across current distance of actualized range.
  //
  // ASSUME  If a key/value pair appears in one of data{Range*,Recent}, it appears in ALL of them.
  //
  // TBD  Assess ranges and sensitivy of magnetometer...
  // TBD  Prevent normalization over rawValue of enum DM_KEY_MAGNETIC_FIELD_ACCURACY?
  //
  private func  normalizeRecent()
  {
    for key in self.dataRecent.keys
    {
      let  recent   = self.dataRecent[key]               ?? 0.0
      var  history  = self.dataNormalizedHysteresis[key] ?? [Double]()

      var  percentage : Double  = 0.0
      var  sum        : Double  = 0.0


      //
      if  key.hasPrefix(DM_KEY_ATTITUDE)  {
	percentage = (recent + DM_MAX_ATTITUDE) / (DM_MAX_ATTITUDE * 2)

      } else if  key.hasPrefix(DM_KEY_ROTATION_RATE)  {
	percentage = abs(recent) / DM_MAX_ROTATION_RATE

      } else if  key.hasPrefix(DM_KEY_GRAVITY)  {
	percentage = (recent + DM_MAX_GRAVITY) / (DM_MAX_GRAVITY * 2)

      } else if  key.hasPrefix(DM_KEY_USER_ACCELERATION)  {
        percentage = abs(recent) / DM_MAX_USER_ACCELERATION

      } else {
        let  high  = self.dataRangeHigh[key]  ?? 0.0
        let  low   = self.dataRangeLow[key]   ?? 0.0

        if  (high-low) > 0  {
          percentage = (recent - low) / (high - low)
        }
      }

      Log.assert(self, f:__FUNCTION__, assertion:(percentage >= 0), msg:"percentage is OUT OF RANGE.  (\(percentage))")  //DEBUG


      history.insert(percentage, atIndex:0)  // front to back: newest to oldest

      if  history.count > DM_HYSTERESIS_ARRAYSIZE  { history.removeLast() }

      self.dataNormalizedHysteresis[key] = history


      //
      for value in history  { sum += value }  // TBD -- use closure shortcuts

      self.dataNormalized[key] = (sum / Double(history.count))
    }

  }  //normalizeRecent()




  //----------------------------------------------------------------------------- -o--
  // MARK: - Helper Methods.

  //-------------------------- -o-
  private func  stringForParameterField(title: String, field: String) -> String
  {
    let  s =    title + "  "
              + (self.dataNormalized[field]! * 100.0).format("3.0")                                    + "%   "
              + self.dataRecent[field]!.signString + " " + abs(self.dataRecent[field]!).format("1.3")  + "  ("
              + self.dataRangeLow[field]!.format("1.1")                                                + ", "
              + self.dataRangeHigh[field]!.format("1.1")                                               + ")"

    return  s
  }


  //-------------------------- -o-
  private func  normalizedValue(key : String) -> Double
  {
    return  (self.captureIteration < 1) ? Double(0.0) : Double(self.dataNormalized[key]!)
  }

}  //class DeviceMotion

