//
//  Logger.swift
//
//  Created by James D. Emrich on 6/19/14.
//  Copyright (c) 2014 Emrich. All rights reserved.
//

import Foundation

// #pragma mark - == Operator Overload ==
func <= (left: LoggerLevel?, right: LoggerLevel?) -> Bool {
    switch (left, right) {
        case let (.Some(a), .Some(b)):
            return b.toRaw() <= a.toRaw();
        default:
            return false;
    }
}

// #pragma mark - == Enums ==
enum LoggerLevel: Int {
    case Info       = 0;
    case Warning    = 1;
    case Error      = 2;
    case Debug      = 3;

    func description() -> String {
        switch self {
            case .Info:
                return "Info";
            case .Warning:
                return "Warning";
            case .Error:
                return "Error";
            case .Debug:
                return "Debug";
        }
    }
}

class Logger {
    // #pragma mark - == Props ==
    let maxFileSize: CUnsignedLongLong = (1024 * 1024) * 1; // file size is in megabytes
    var baseLoggerLevel: LoggerLevel?;
    var printToConsole: Bool = true;
    var dateFormatter: NSDateFormatter? = nil;
    var fileHandle: NSFileHandle?    = nil;
    var writeToFileURL: NSURL? = nil {
        didSet {
            self.fileHandle?.closeFile();
            self.fileHandle = nil;
            
            if let writeToFileURL = self.writeToFileURL {
                let fileManager: NSFileManager = NSFileManager.defaultManager();
                var hasFile = fileManager.fileExistsAtPath(writeToFileURL.path);
                var writeAppDetails = false;
                if !hasFile {
                    writeAppDetails = true;
                    hasFile = fileManager.createFileAtPath(writeToFileURL.path, contents: nil, attributes: nil);
                    if !hasFile {
                        self.log(message: "Failed to create file at path \(writeToFileURL.path)", logLevel: .Error);
                    }
                }
                
                var fileError: NSError? = nil;
                self.fileHandle = NSFileHandle.fileHandleForWritingToURL(self.writeToFileURL, error: &fileError);
                
                if let fileHandle = self.fileHandle {
                    fileHandle.seekToEndOfFile();
                    
                    if writeAppDetails {
                        self.logAppDetails();
                    }
                }
                else {
                    self.log(message: "Failed to open log file for writing with error: \(fileError?.localizedDescription!)", logLevel: .Error);
                }
            }
        }
    }
    
    // #pragma mark - == Static vars ==
    struct _SharedInstanceStatics {
        static var sharedInstanceOnceToken: dispatch_once_t = 0;
        static var sharedInstance: Logger? = nil;
    }
    
    // #pragma mark - == Logger ==
    init() {
       // We have nothing here :)
    }

    deinit {
        self.fileHandle?.closeFile();
    }
    
    class func sharedInstance(loggerLevel: LoggerLevel = .Debug, filePath: String? = nil, printToConsole: Bool = true) -> Logger {
        dispatch_once(&_SharedInstanceStatics.sharedInstanceOnceToken) {
            var sharedInstance = Logger();
            sharedInstance.setupLogger(loggerLevel: loggerLevel, filePath: filePath, printToConsole: printToConsole);
            _SharedInstanceStatics.sharedInstance = sharedInstance;
        }
        
        return _SharedInstanceStatics.sharedInstance!;
    }
    
    // #pragma mark - == Public Log Methods ==
    func debug(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__, logMessage: Any...) {
        if self.baseLoggerLevel <= LoggerLevel.Debug {
            var message = self.messageFromArgs(logMessage);
            self.verboseLog(logMessage: message, logLevel: .Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
        }
    }

    func info(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__, logMessage: Any...) {
        if self.baseLoggerLevel <= LoggerLevel.Info {
            var message = self.messageFromArgs(logMessage);
            self.verboseLog(logMessage: message, logLevel: .Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate);
        }
    }
    
    func warning(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__, logMessage: Any...) {
        if self.baseLoggerLevel <= LoggerLevel.Warning {
            var message = self.messageFromArgs(logMessage);
            self.verboseLog(logMessage: message, logLevel: .Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate);
        }
    }
    
    func error(functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__, logMessage: Any...) {
        if self.baseLoggerLevel <= LoggerLevel.Error {
            var message = self.messageFromArgs(logMessage);
            self.verboseLog(logMessage: message, logLevel: .Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate);
        }
    }
    
    // #pragma mark - == Public Methods ==
    func setupLogger(loggerLevel: LoggerLevel = .Debug, filePath: String? = nil, printToConsole: Bool = true) {
        self.printToConsole = printToConsole;
        self.baseLoggerLevel = loggerLevel;
        
        self.dateFormatter = NSDateFormatter();
        self.dateFormatter!.timeZone = NSTimeZone(name: "UTC");
        self.dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS";
        
        if let filePath = filePath {
            self.writeToFileURL = NSURL.fileURLWithPath(filePath.stringByDeletingPathExtension);
        }
        else {
            self.writeToFileURL = nil;
        }
    }
    
    func log(message: String = "", logLevel: LoggerLevel = .Debug) {
        if self.baseLoggerLevel <= logLevel {
            let now: NSDate = NSDate.date();
            var formattedDate: String = now.description;
            if let dateFormatter = self.dateFormatter {
                formattedDate = dateFormatter.stringFromDate(now);
            }

            let details: String = "\(formattedDate): [\(logLevel.description())] \(message) \n";

            if self.printToConsole {
                print(details);
            }
            
            let data: NSData? = details.dataUsingEncoding(NSUTF8StringEncoding);

            self.fileHandle?.writeData(data);
        }
    }
    
    func verboseLog(logMessage: String = "", logLevel: LoggerLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        if self.baseLoggerLevel <= logLevel {
            var realFunctionName: String = functionName;
            let functionNameDuplicateLength = functionNameDuplicate.lengthOfBytesUsingEncoding(NSUTF8StringEncoding);
            let functionNameLength = functionName.lengthOfBytesUsingEncoding(NSUTF8StringEncoding);
            
            if functionNameLength < functionNameDuplicateLength {
                let range: Range = functionNameDuplicate.rangeOfString(functionName, options: .LiteralSearch);
                realFunctionName = functionNameDuplicate.stringByReplacingCharactersInRange(range, withString: "");
            }
            
            let details: String = "[\(fileName.lastPathComponent):\(lineNumber)] [\(realFunctionName)] \(logMessage)";
            self.log(message: details, logLevel: logLevel);
        }
    }
    
    // #pragma mark - == Private Methods ==
    func logAppDetails() {
        let infoDictionary: NSDictionary = NSBundle.mainBundle().infoDictionary;
        let processInfo: NSProcessInfo = NSProcessInfo.processInfo();
        let versionString = infoDictionary["CFBundleShortVersionString"] as String;
        let bundleVersion = infoDictionary["CFBundleVersion"] as String;
        let details: String = "[Appname: \(processInfo.processName!)] [Version: \(versionString)] [Build: \(bundleVersion)] [PID: \(processInfo.processIdentifier)]";
        
        self.log(message: details, logLevel: .Info);
    }
    
    func messageFromArgs(args: Any[]) -> String {
        var message = "";
        for (i, arg) in enumerate(args) {
            if i != 0 {
                print(" ", &message);
            }
            print(arg, &message);
        }
        
        return message;
    }
    
    func isFileSizeOverMax() -> Bool {
        if let writeToFileURL = self.writeToFileURL {
            let fileAttributes = NSFileManager.defaultManager().attributesOfItemAtPath(writeToFileURL.path, error: nil);
            
            return fileAttributes.fileSize() > self.maxFileSize;
        }
        
        return false;
    }
}
