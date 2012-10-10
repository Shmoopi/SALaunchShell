/* 
 # SALaunchShell - NSTask wrapper for launching shell scripts
 # from NSTask and launching shell scripts with Authentication
 # using STPrivilegedTask - an NSTask-like wrapper around AuthorizationExecuteWithPrivileges
 # Copyright (C) 2009-2012 Shmoopi LLC <shmoopillc@gmail.com> <http://www.shmoopi.net/>
 #
 # BSD License
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions are met:
 #     * Redistributions of source code must retain the above copyright
 #       notice, this list of conditions and the following disclaimer.
 #     * Redistributions in binary form must reproduce the above copyright
 #       notice, this list of conditions and the following disclaimer in the
 #       documentation and/or other materials provided with the distribution.
 #     * Neither the name of Shmoopi LLC nor that of any other
 #       contributors may be used to endorse or promote products
 #       derived from this software without specific prior written permission.
 #
 # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 # ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 # WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 # DISCLAIMED. IN NO EVENT SHALL  BE LIABLE FOR ANY
 # DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 # (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 # LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 # ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 # (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 # SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SALaunchShell.h"
#import "STPrivilegedTask.h"

@implementation SALaunchShell

// Execute a shell script without root access
- (NSString *)LaunchShell:(NSString *)fileName withError:(NSUInteger)error {
    // Set up a task
    NSTask *task = [[NSTask alloc] init];
    // Make sure the launch path @"/bin/sh" exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/bin/sh"]) {
        // Set the launch path
        [task setLaunchPath:@"/bin/sh"];
    } else {
        // We've got a problem
        error = kSAShutdownBinSHNotFound;
    }
    // Set the script location if not null
    if (fileName) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
            // Set the location
            [task setArguments:[NSArray arrayWithObjects:fileName, nil]];
        } else {
            // Script not found
            error = kSAShutdownScriptNotFound;
            // Return the error
            return nil;
        }
    } else {
        // Location not provided
        error = kSAShutdownScriptNotGiven;
        // Return the error
        return nil;
    }
    // Pipe it out
    NSPipe *outpipe = [NSPipe pipe];
    [task setStandardOutput:outpipe];
    
    // Try running the command
    @try {
        // Launch the task
        [task launch];
        // Wait until it finishes
        [task waitUntilExit];
    }
    @catch (NSException *exception) {
        // There was an error
        error = kSAShutdownScriptFailed;
        // Return the error
        return nil;
    }
    
    // Read the file to see the output
    NSFileHandle * read = [outpipe fileHandleForReading];
    NSData * dataRead = [read readDataToEndOfFile];
    NSString * stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    
    // Check to make sure some output was given
    if (!stringRead)
        // No output was given by the script, not good, but not breaking bad
        error = kSAShutdownNoOutputReceived;
    
    // Return the output
    return stringRead;
}

// Execute a shell script with root access
- (NSString *)LaunchShellWithAuth:(NSString *)fileName withError:(NSUInteger)error {
    // Set up a privileged task
    STPrivilegedTask *task = [[STPrivilegedTask alloc] init];
    // Make sure the launch path @"/bin/sh" exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/bin/sh"]) {
        // Set the launch path
        [task setLaunchPath:@"/bin/sh"];
    } else {
        // We've got a problem
        error = kSAShutdownBinSHNotFound;
    }
    // Set the script location if not null
    if (fileName) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
            // Set the location
            [task setArguments:[NSArray arrayWithObjects:fileName, nil]];
        } else {
            // Script not found
            error = kSAShutdownScriptNotFound;
            // Return the error
            return nil;
        }
    } else {
        // Location not provided
        error = kSAShutdownScriptNotGiven;
        // Return the error
        return nil;
    }    
    // Try running the command
    @try {
        // Launch the task
        [task launch];
        // Wait until it finishes
        [task waitUntilExit];
    }
    @catch (NSException *exception) {
        // There was an error
        error = kSAShutdownScriptFailed;
        // Return the error
        return nil;
    }
    
    // Read the file to see the output
    NSFileHandle *read = [task outputFileHandle];
    NSData * dataRead = [read readDataToEndOfFile];
    NSString * stringRead = [[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding];
    
    // Check to make sure some output was given
    if (!stringRead)
        // No output was given by the script, not good, but not breaking bad
        error = kSAShutdownNoOutputReceived;
    
    // Return the output as a string
    return stringRead;
}

@end
