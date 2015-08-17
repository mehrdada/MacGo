//
//  main.m
//  MG
//
//  Created by Tim Debo on 5/19/14.
//
//

#import <Cocoa/Cocoa.h>
#import "ServerProcess.h"

ServerProcess *serverProcess;
int main(int argc, const char * argv[])
{
    serverProcess = [[ServerProcess alloc] init];
    return NSApplicationMain(argc, argv);
}
