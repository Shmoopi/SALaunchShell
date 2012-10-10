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

#import <Foundation/Foundation.h>

@interface SALaunchShell : NSObject

/*  Constants used for determining errors */
enum {
    kSAShutdownBinSHNotFound     = 1,
    kSAShutdownScriptNotGiven    = 2,
    kSAShutdownScriptNotFound    = 3,
    kSAShutdownScriptFailed      = 4,
    kSAShutdownNoOutputReceived  = 5
};

// Execute a shell script without root access
- (NSString *)LaunchShell:(NSString *)fileName withError:(NSUInteger)error;

// Execute a shell script with root access
- (NSString *)LaunchShellWithAuth:(NSString *)fileName withError:(NSUInteger)error;

@end
