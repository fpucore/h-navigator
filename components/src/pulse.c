#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <string.h>
#include <signal.h>
#include <poll.h>

#define FIFO_PATH "/tmp/h_navigator_pulse"
#define TIMEOUT_MS 15000 // 15secs before declaring flatline
#define KEY_DIR "/tmp/1V/sys/ctrl/strgctrl0/strgpri0/vfunit0-drive_C/"

// secure_shred function
void secure_shred(const char *filepath) {
    FILE *fp = fopen(filepath, "r+");
    if (!fp) {
        printf("[*] Keys are already destroyed or missing: %s\n", filepath);
        return;
    }

    fseek(fp, 0, SEEK_END);
    long file_size = ftell(fp);
    rewind(fp);

    if (file_size > 0) {
        char *wipe_buffer = calloc(1, file_size);
        if (wipe_buffer) {
            fwrite(wipe_buffer, 1, file_size, fp);
            fflush(fp);
            fsync(fileno(fp)); 
            free(wipe_buffer);
        }
    }
    
    fclose(fp);
    unlink(filepath);
    printf("[+] Securely removed: %s\n", filepath);
}

// Flatline handler
void handle_flatline(pid_t h_nav_pgid) {
    printf("\n[!!!] PULSE FLATLINE DETECTED [!!!]\n");
    
    const char *key_files[] = {
        "h_navigator_auth_tmp_a",
        "h_navigator_auth_tmp_b",
        "h_navigator_auth_tmp_c",
        "h_navigator_auth_tmp_d"
    };
    int num_keys = sizeof(key_files) / sizeof(key_files[0]);
    char filepath[512];

    // 1. Shred all authentication keys
    for (int i = 0; i < num_keys; i++) {
        snprintf(filepath, sizeof(filepath), "%s%s", KEY_DIR, key_files[i]);
        secure_shred(filepath);
    }
    
    // 2. Absolute Process Annihilation
    if (h_nav_pgid > 1) {
        printf("[!] Executing emergency termination procedure...\n");
        
        // Kill the script exec
        kill(h_nav_pgid, SIGKILL);
        
        // System-level annihilation of the env
        system("pkill -9 -f brave-browser-nightly");
        system("pkill -9 -f sextant.sh");
    }
    
    // 3. Clean up FIFO
    unlink(FIFO_PATH);
    
    printf("[*] Teardown complete. Exiting.\n");
    exit(EXIT_FAILURE);
}

int main(int argc, char *argv[]) {
    int fd;
    struct pollfd pfd;
    char buffer[16];

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <PGID>\n", argv[0]);
        return EXIT_FAILURE;
    }

    pid_t h_nav_pgid = (pid_t) atoi(argv[1]);
    if (h_nav_pgid <= 1) {
        fprintf(stderr, "Invalid PGID provided.\n");
        return EXIT_FAILURE;
    }

    // Create FIFO with strict permissions (only user can r/w)
    unlink(FIFO_PATH);
    if (mkfifo(FIFO_PATH, 0600) == -1) {
        perror("Failed to create pulse FIFO");
        return EXIT_FAILURE;
    }

    printf("[*] Pulse monitor active on %s monitoring PGID %d\n", FIFO_PATH, h_nav_pgid);

    // Open in non-blocking mode first to avoid blocking on open()
    fd = open(FIFO_PATH, O_RDWR | O_NONBLOCK);
    if (fd == -1) {
        perror("Failed to open FIFO");
        unlink(FIFO_PATH);
        return EXIT_FAILURE;
    }

    pfd.fd = fd;
    pfd.events = POLLIN;

    while (1) {
        // Wait for data with timeout
        int ret = poll(&pfd, 1, TIMEOUT_MS);

        if (ret == 0) {
            // No pulse received = timeout reached
            handle_flatline(h_nav_pgid);
        } else if (ret > 0) {
            if (pfd.revents & POLLIN) {
                // Pulse received, flush pipe
                ssize_t bytes_read = read(fd, buffer, sizeof(buffer));
                if (bytes_read > 0) {
                    // Pulse acknowledged. Loop continues and resets timer
                }
            }
        } else {
            perror("Poll error.");
            break;
        }
    }

    close(fd);
    unlink(FIFO_PATH);
    return EXIT_SUCCESS;
}
