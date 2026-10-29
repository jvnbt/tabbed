#include <sandbox.h>
#include <stdio.h>

// App Sandbox prevents the cross-app Accessibility operations this app needs.
// Seatbelt can restrict networking independently. Its profile API is deprecated:
// fail closed if a future macOS stops supporting it. Never load a mutable policy
// from disk or allow an environment variable to disable the restriction.
int tabbed_apply_network_sandbox(void) {
    static const char policy[] =
        "(version 1)\n"
        "(allow default)\n"
        "(deny network*)\n"
        // Prevent delegation of HTTP requests to the background URL session service.
        "(deny mach-lookup (global-name \"com.apple.nsurlsessiond\"))\n";
    char *error = NULL;
    int result = sandbox_init(policy, 0, &error);
    if (result != 0) {
        fputs("Tabbed Local: cannot enforce offline policy; refusing to start.\n", stderr);
    }
    if (error != NULL) {
        sandbox_free_error(error);
    }
    return result;
}
