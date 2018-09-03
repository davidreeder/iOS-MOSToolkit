//
//  UIDeviceOrientationExtension.swift
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

import Foundation



//----------------------------------------------------- -o--
extension UIDeviceOrientation
{
  //
  var  description : String
    {
      var  valueString = ""

      switch self
      {
        case .Unknown:             valueString = "Unknown"
        case .Portrait:            valueString = "Portrait"
        case .PortraitUpsideDown:  valueString = "PortraitUpsideDown"
        case .LandscapeLeft:       valueString = "LandscapeLeft"
        case .LandscapeRight:      valueString = "LandscapeRight"
        case .FaceUp:              valueString = "FaceUp"
        case .FaceDown:            valueString = "FaceDown"
      }

      return  valueString
    }
}

