//
//  UIAlertViewExtension.swift
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

import Foundation
import UIKit



//-------------------------------------------------------------------- -o--
extension UIAlertView
{
  //---------------------------- -o-
  class func  presentAlert( withTitle title  : String,
                            message          : String )
  {
    let  alertView = UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: "OK")

    alertView.show()
  }
}

