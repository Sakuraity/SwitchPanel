#import "PrivilegedPmset.h"
#include <stdlib.h>
#include <stdio.h>

OSStatus SPAuthorizationRunPmset(AuthorizationRef authRef, NSArray<NSString *> *arguments) {
    NSUInteger count = arguments.count;
    if (count == 0) {
        return errAuthorizationBadAddress;
    }

    char **argv = malloc(sizeof(char *) * (count + 1));
    if (!argv) {
        return errAuthorizationDenied;
    }

    for (NSUInteger i = 0; i < count; i++) {
        argv[i] = strdup(arguments[i].UTF8String);
        if (!argv[i]) {
            for (NSUInteger j = 0; j < i; j++) {
                free(argv[j]);
            }
            free(argv);
            return errAuthorizationDenied;
        }
    }
    argv[count] = NULL;

    FILE *pipe = NULL;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    OSStatus status = AuthorizationExecuteWithPrivileges(
        authRef,
        "/usr/bin/pmset",
        0,
        argv,
        &pipe
    );
#pragma clang diagnostic pop

    for (NSUInteger i = 0; i < count; i++) {
        free(argv[i]);
    }
    free(argv);

    if (pipe != NULL) {
        char buffer[256];
        while (fgets(buffer, sizeof(buffer), pipe) != NULL) { /* drain */ }
        fclose(pipe);
    }

    return status;
}