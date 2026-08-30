#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

int main(int argc, char *argv[]) {
    char *home = getenv("HOME");
    if (!home) {
        fprintf(stderr, "Error: HOME environment variable is not set.\n");
        return EXIT_FAILURE;
    }

    char func_path[512];
    snprintf(func_path, sizeof(func_path), "%s/.hwm/scripts/h_navigator_profile", home);

    // Replace argv[0] with absolute func path
    argv[0] = func_path;

    // Hand exec > interpreter func
    execv(func_path, argv);

    // If execv returns then func failed to launch
    perror("Error: Failed to launch H Navigator profile interpreter");
    return EXIT_FAILURE;
}
