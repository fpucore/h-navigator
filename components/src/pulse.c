#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <string.h>
#include <signal.h>
#include <poll.h>
#include <errno.h>

#define TIMEOUT_MS 30000
#define KEY_DIR "/tmp/1V/sys/ctrl/strgctrl0/strgpri0/vfunit0-drive_C/"

static char fifo_path[512];

/*
 * Securely destroy a file.
 */
void secure_shred(const char *filepath)
{
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


/*
 * Emergency flatline handler.
 */
void handle_flatline(pid_t h_nav_pgid, const char *pulse_name)
{
    printf("\n[!!!] %s PULSE FLATLINE DETECTED [!!!]\n", pulse_name);

    const char *key_files[] = {
        "h_navigator_auth_tmp_a",
        "h_navigator_auth_tmp_b",
        "h_navigator_auth_tmp_c",
        "h_navigator_auth_tmp_d"
    };

    int num_keys = sizeof(key_files) / sizeof(key_files[0]);
    char filepath[512];

    /*
     * 1. Destroy authentication keys.
     */
    for (int i = 0; i < num_keys; i++) {
        snprintf(filepath,
                 sizeof(filepath),
                 "%s%s",
                 KEY_DIR,
                 key_files[i]);

        secure_shred(filepath);
    }

    /*
     * 2. Terminate H Navigator environment.
     */
    if (h_nav_pgid > 1) {
        printf("[!] Executing emergency termination procedure...\n");

        kill(h_nav_pgid, SIGKILL);

        system("pkill -9 -f brave-browser-nightly");
        system("pkill -9 -f sextant.sh");
    }

    /*
     * 3. Remove only our own FIFO.
     */
    unlink(fifo_path);

    printf("[*] %s teardown complete. Exiting.\n", pulse_name);

    exit(EXIT_FAILURE);
}


int main(int argc, char *argv[])
{
    int fd;
    struct pollfd pfd;
    char buffer[16];

    if (argc < 3) {
        fprintf(stderr,
                "Usage: %s <neck|wrist> <PGID>\n",
                argv[0]);

        return EXIT_FAILURE;
    }

    const char *pulse_name = argv[1];

    /*
     * Validate pulse identity.
     */
    if (strcmp(pulse_name, "neck") != 0 &&
        strcmp(pulse_name, "wrist") != 0) {

        fprintf(stderr,
                "Invalid pulse type: %s\n"
                "Expected: neck or wrist\n",
                pulse_name);

        return EXIT_FAILURE;
    }

    pid_t h_nav_pgid = (pid_t)atoi(argv[2]);

    if (h_nav_pgid <= 1) {
        fprintf(stderr, "Invalid PGID provided.\n");
        return EXIT_FAILURE;
    }

    /*
     * Each pulse gets its own independent FIFO.
     */
    snprintf(fifo_path,
             sizeof(fifo_path),
             "/tex/h-swap/h_navigator_pulse_%s",
             pulse_name);

    /*
     * Create FIFO with strict permissions.
     */
    unlink(fifo_path);

    if (mkfifo(fifo_path, 0600) == -1) {
        perror("Failed to create pulse FIFO");
        return EXIT_FAILURE;
    }

    printf("[*] %s pulse monitor active\n", pulse_name);
    printf("[*] FIFO: %s\n", fifo_path);
    printf("[*] Monitoring PGID: %d\n", h_nav_pgid);

    /*
     * O_RDWR prevents open() from blocking waiting
     * for the H Navigator writer.
     */
    fd = open(fifo_path, O_RDWR | O_NONBLOCK);

    if (fd == -1) {
        perror("Failed to open FIFO");
        unlink(fifo_path);
        return EXIT_FAILURE;
    }

    pfd.fd = fd;
    pfd.events = POLLIN;

    while (1) {

        int ret = poll(&pfd, 1, TIMEOUT_MS);

        if (ret == 0) {

            /*
             * No heartbeat for 30 seconds.
             */
            handle_flatline(h_nav_pgid, pulse_name);

        } else if (ret > 0) {

            if (pfd.revents & POLLIN) {

                /*
                 * Drain all currently available heartbeat data.
                 */
                while (read(fd, buffer, sizeof(buffer)) > 0) {
                    /* heartbeat acknowledged */
                }
            }

            /*
             * Handle broken/error conditions.
             */
            if (pfd.revents & (POLLERR | POLLHUP | POLLNVAL)) {
                printf("[!] %s pulse FIFO error.\n", pulse_name);
            }

        } else {

            if (errno == EINTR)
                continue;

            perror("Poll error.");
            break;
        }
    }

    close(fd);
    unlink(fifo_path);

    return EXIT_SUCCESS;
}
