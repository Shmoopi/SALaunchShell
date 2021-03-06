/*
 # STPrivilegedTask - NSTask-like wrapper around AuthorizationExecuteWithPrivileges
 # Copyright (C) 2009-2011 Sveinbjorn Thordarson <sveinbjornt@gmail.com>
 #
 # BSD License
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions are met:
 #     * Redistributions of source code must retain the above copyright
 #       notice, this list of conditions and the following disclaimer.
 #     * Redistributions in binary form must reproduce the above copyright
 #       notice, this list of conditions and the following disclaimer in the
 #       documentation and/or other materials provided with the distribution.
 #     * Neither the name of Sveinbjorn Thordarson nor that of any other
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

#import "STPrivilegedTask.h"
#import <stdio.h>
#import <unistd.h>

@implementation STPrivilegedTask

- (id)init
{
    if ((self = [super init])) 
    {
        launchPath = @"";
        cwd = [[NSString alloc] initWithString: [[NSFileManager defaultManager] currentDirectoryPath]];
        arguments = [[NSArray alloc] init];
        isRunning = NO;
        outputFileHandle = NULL;
    }
    return self;
}


-(id)initWithLaunchPath: (NSString *)path arguments:  (NSArray *)args
{
    if ((self = [self initWithLaunchPath: path]))
    {
        [self setArguments: args];
    }
    return self;
}

-(id)initWithLaunchPath: (NSString *)path
{
    if ((self = [self init]))
    {
        [self setLaunchPath: path];
    }
    return self;
}

#pragma mark -

+(STPrivilegedTask *)launchedPrivilegedTaskWithLaunchPath:(NSString *)path arguments:(NSArray *)args
{
    STPrivilegedTask *task = [[STPrivilegedTask alloc] initWithLaunchPath: path arguments: args];
    [task launch];
    [task waitUntilExit];
    return task;
}

+(STPrivilegedTask *)launchedPrivilegedTaskWithLaunchPath:(NSString *)path
{
    STPrivilegedTask *task = [[STPrivilegedTask alloc] initWithLaunchPath: path];
    [task launch];
    [task waitUntilExit];
    return task;
}

#pragma mark -

- (NSArray *)arguments
{
    return arguments;
}

- (NSString *)currentDirectoryPath;
{
    return cwd;
}

- (BOOL)isRunning
{
    return isRunning;
}

- (NSString *)launchPath
{
    return launchPath;
}

- (int)processIdentifier
{
    return pid;
}

- (int)terminationStatus
{
    return terminationStatus;
}

- (NSFileHandle *)outputFileHandle;
{
    return outputFileHandle;
}

#pragma mark -

-(void)setArguments:(NSArray *)args
{
    arguments = args;
}

-(void)setCurrentDirectoryPath:(NSString *)path
{
    cwd = path;
}

-(void)setLaunchPath:(NSString *)path
{
    launchPath = path;
}

# pragma mark -

// return 0 for success
-(int) launch
{
    OSStatus                err = noErr;
    short                   i;
    const char              *toolPath = [launchPath fileSystemRepresentation];
    
    AuthorizationRef        authorizationRef;
    AuthorizationItem       myItems = {kAuthorizationRightExecute, strlen(toolPath), &toolPath, 0};
    AuthorizationRights     myRights = {1, &myItems};
    AuthorizationFlags      flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
    
    NSUInteger            argumentsCount = [arguments count];
    char                    *args[argumentsCount + 1];
    FILE                    *outputFile;

    // Use Apple's Authentication Manager APIs to get an Authorization Reference
    // These Apple APIs are quite possibly the most horrible of the Mac OS X APIs
    
    // create authorization reference
    err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
    if (err != errAuthorizationSuccess)
        return err;
    
    // pre-authorize the privileged operation
    err = AuthorizationCopyRights(authorizationRef, &myRights, kAuthorizationEmptyEnvironment, flags, NULL);
    if (err != errAuthorizationSuccess) 
        return err;
    
    // OK, at this point we have received authorization for the task.
    // Let's prepare to launch it
    
    // first, construct an array of c strings from NSArray w. arguments
    for (i = 0; i < argumentsCount; i++) 
    {
        NSString *theString = [arguments objectAtIndex:i];
        NSUInteger stringLength = [theString length];
        
        args[i] = malloc((stringLength + 1) * sizeof(char));
        snprintf(args[i], stringLength + 1, "%s", [theString fileSystemRepresentation]);
    }
    args[argumentsCount] = NULL;
    
    // change to the current dir specified
    char *prevCwd = (char *)getcwd(nil, 0);
    chdir([cwd fileSystemRepresentation]);
    
    //use Authorization Reference to execute script with privileges
    err = AuthorizationExecuteWithPrivileges(authorizationRef, [launchPath fileSystemRepresentation], kAuthorizationFlagDefaults, args, &outputFile);
    
    // OK, now we're done executing, let's change back to old dir
    chdir(prevCwd);
    
    // free the malloc'd argument strings
    for (i = 0; i < argumentsCount; i++)
        free(args[i]);
    
    // free the auth ref
    AuthorizationFree(authorizationRef, kAuthorizationFlagDefaults);
    
    // we return err if execution failed
    if (err != errAuthorizationSuccess) 
        return err;
    else
        isRunning = YES;
    
    // get file handle for the command output
    outputFileHandle = [[NSFileHandle alloc] initWithFileDescriptor: fileno(outputFile) closeOnDealloc: YES];
    pid = fcntl(fileno(outputFile), F_GETOWN, 0);
    
    // start monitoring task
    checkStatusTimer = [NSTimer scheduledTimerWithTimeInterval: 0.10 target: self selector:@selector(_checkTaskStatus) userInfo: nil repeats: YES];
        
    return err;
}

- (void)terminate
{
    // This doesn't work without a PID, and we can't get one.  Stupid Security API
    /*    int ret = kill(pid, SIGKILL);
     
     if (ret != 0)
     NSLog(@"Error %d", errno);*/
}

// hang until task is done
- (void)waitUntilExit
{
    waitpid([self processIdentifier], &terminationStatus, 0);
    isRunning = NO;
}

#pragma mark -

// check if privileged task is still running
- (void)_checkTaskStatus
{    
    // see if task has terminated
    int mypid = waitpid([self processIdentifier], &terminationStatus, WNOHANG);
    if (mypid != 0)
    {
        isRunning = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName: STPrivilegedTaskDidTerminateNotification object:self];
        [checkStatusTimer invalidate];
    }
}

#pragma mark -

- (NSString *)description
{
    NSArray *args = [self arguments];
    NSString *cmd = [self launchPath];
    int i;
    for (i = 0; i < [args count]; i++)
        cmd = [cmd stringByAppendingFormat: @" %@", [args objectAtIndex: i]];
    
    return [[super description] stringByAppendingFormat: @" %@", cmd];
}

@end