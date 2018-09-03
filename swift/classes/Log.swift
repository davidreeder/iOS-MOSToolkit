//
// Log.swift
//
//
//---------------------------------------------------------------------
//     Copyright (C) 2014-2015 David Reeder.  ios@mobilesound.org
//     Distributed under the Boost Software License, Version 1.0.
//     (See LICENSE_1_0.txt or http://www.boost.org/LICENSE_1_0.txt)
//---------------------------------------------------------------------

import Foundation


//----------------------------------------------- -o--
class Log
{
  // MARK: - Public Methods.

  //--------------- -o-
  class func  mark(classObject: AnyObject, f funcName: String, msg message: String = "") {
    self.writeNSLog(classObject, funcName:funcName, message:message, debugTag:"MARK")
  }

  class func  debug(classObject: AnyObject, f funcName: String, msg message: String = "") {       
    self.writeNSLog(classObject, funcName:funcName, message:message, debugTag:"DEBUG")
  }

  class func  info(classObject: AnyObject, f funcName: String, msg message: String = "") {        
    self.writeNSLog(classObject, funcName:funcName, message:message, debugTag:"INFO")
  }

  class func  warning(classObject: AnyObject, f funcName: String, msg message: String = "") {        
    self.writeNSLog(classObject, funcName:funcName, message:message, debugTag:"WARNING")
  }

  class func  error(classObject: AnyObject, f funcName: String, msg message: String = "") {        
    self.writeNSLog(classObject, funcName:funcName, message:message, debugTag:"ERROR")
  }



  //--------------- -o-
  // RETURN:
  //   true   Upon error,
  //   false  Otherwise.
  //
  class func  nsError(classObject: AnyObject, f funcName: String, error: NSError?) -> Bool
  {
    guard let  errorUW = error else  { return false }

    //
    let errorMessage  = "\(errorUW.domain) : \(errorUW.code)\n\(errorUW.userInfo)"

    self.writeNSLog(classObject, funcName:funcName, message:errorMessage, debugTag:"NSERROR")

    return true
  }


  //--------------- -o-
  class func  assert(classObject: AnyObject, f funcName: String, assertion: Bool, msg message: String = "") -> Bool
  {
    if  assertion  { return false }

    self.writeNSLog(classObject, funcName:funcName, message:message, debugTag:"ASSERT")
    return true
  }




  //----------------------------------------------- -o--
  // MARK: - Public Method Helpers.

  //--------------- -o-
  // classObject  Call with self.
  // funcName     Call with __FUNCTION__.
  //
  // XXX TBD  AnyObject.classForCoder only works when class inherits from Foundation (NSObject).  alternatives?
  // TBD  Distinguish between class and instance methods?
  //
  class func  signature(classObject: AnyObject, f funcName: String, msg message: String = "") -> String
  {
    var  className = "(UNKNOWN CLASS)"

    if let classObj = classObject.classForCoder  {
      className = NSStringFromClass(classObj).componentsSeparatedByString(".")[1]
    }

    let  formattedMessage  = (message.isEmpty) ? "" : " -- \(message)"

    return  "\(className) .\(funcName)\(formattedMessage)"
  }
  
  
  

  //----------------------------------------------- -o--
  // MARK: - Private Methods.

  //--------------- -o-
  // classObject  Call with self.
  // funcName     Call with __FUNCTION__.
  // message      "" or non-empty string.
  // debugTag     Prefix for log message.
  //
  private
  class func  writeNSLog(  classObject: AnyObject,
                              funcName: String,
                               message: String,
                              debugTag: String )
  {
    let  funcSignature  = self.signature(classObject, f: funcName, msg:message)
    let  logMessage     = " \(debugTag)  \(funcSignature)"

    NSLog(logMessage);
  }

}  //class Log

