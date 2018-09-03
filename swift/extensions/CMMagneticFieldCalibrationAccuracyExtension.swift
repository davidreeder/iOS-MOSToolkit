//
// CMMagneticFieldCalibrationAccuracyExtension.swift
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

import Foundation
import CoreMotion



//----------------------------------------------------- -o--
extension  CMMagneticFieldCalibrationAccuracy 
{
  //
  var  description : String
    {
      var  valueString  = ""

      switch self.rawValue
      {
        case CMMagneticFieldCalibrationAccuracyUncalibrated.rawValue:  valueString  = "Uncalibrated"
        case CMMagneticFieldCalibrationAccuracyLow.rawValue:           valueString  = "Low"
        case CMMagneticFieldCalibrationAccuracyMedium.rawValue:        valueString  = "Medium"
        case CMMagneticFieldCalibrationAccuracyHigh.rawValue:          valueString  = "High"
        default:          					       valueString  = "(UNKNOWN)"
      }

      return  valueString 
    }
}

