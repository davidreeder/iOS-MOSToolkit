//
//  DoubleExtension.swift
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

import Foundation



//-------------------------------------------------- -o--
extension Double
{
  // MARK: - Public Properties.
  //

  //---------------------------- -o-
  var  signString : String
    {
           if  self > 0  { return "+" }
      else if  self < 0  { return "-" }
      else               { return " " }

    }


  //---------------------------- -o-
  var  signValue : Int
    {
           if  self > 0  { return  1 } 
      else if  self < 0  { return -1 } 
      else               { return  0 }
    }




  //-------------------------------------------------- -o--
  // MARK: - Public Methods.
  //

  //---------------------------- -o-
  func  format(f: String) -> String  { return  NSString(format: "%\(f)f", self) as String }

}  //extension Double

