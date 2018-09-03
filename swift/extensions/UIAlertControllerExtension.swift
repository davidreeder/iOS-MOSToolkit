//
//  UIAlertControllerExtension.swift
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
@available(iOS 8.0, *)
extension UIAlertController
{
  //---------------------------- -o-
  class func  presentAlert( withTitle title        : String,
                            message                : String,
                            fromViewController vc  : UIViewController )
  {
    let  alert     = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    let  actionOK  = UIAlertAction(title: "OK", style: .Default, handler: nil)

    alert.addAction(actionOK)

    vc.presentViewController(alert, animated: true, completion: nil)
  }
}

