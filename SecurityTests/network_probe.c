#include <sys/socket.h>
#include <arpa/inet.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int tabbed_apply_network_sandbox(void);

// Test-only executable, never included in the app. All probes use loopback.
int main(int argc, char **argv) {
    if (argc != 5) return 2;
    int blocked = strcmp(argv[1], "blocked") == 0;
    int family = strcmp(argv[2], "ipv6") == 0 ? AF_INET6 : AF_INET;
    int type = strcmp(argv[3], "udp") == 0 ? SOCK_DGRAM : SOCK_STREAM;
    int port = atoi(argv[4]);
    if (blocked && tabbed_apply_network_sandbox() != 0) return 3;
    int fd = socket(family, type, 0);
    int result = -1;
    if (fd >= 0) {
        struct sockaddr_storage address = {0};
        socklen_t size;
        if (family == AF_INET) {
            struct sockaddr_in *v4 = (struct sockaddr_in *)&address;
            v4->sin_family = AF_INET;
            v4->sin_port = htons(port);
            inet_pton(AF_INET, "127.0.0.1", &v4->sin_addr);
            size = sizeof(*v4);
        } else {
            struct sockaddr_in6 *v6 = (struct sockaddr_in6 *)&address;
            v6->sin6_family = AF_INET6;
            v6->sin6_port = htons(port);
            inet_pton(AF_INET6, "::1", &v6->sin6_addr);
            size = sizeof(*v6);
        }
        result = type == SOCK_DGRAM
            ? (int)sendto(fd, "test", 4, 0, (struct sockaddr *)&address, size)
            : connect(fd, (struct sockaddr *)&address, size);
    }
    int saved_errno = errno;
    if (fd >= 0) close(fd);
    if (blocked) {
        if (result == -1 && (saved_errno == EPERM || saved_errno == EACCES)) {
            printf("DENIED by OS (errno=%d)\n", saved_errno);
            return 0;
        }
        fprintf(stderr, "Expected policy denial, got result=%d errno=%d\n", result, saved_errno);
        return 1;
    }
    if (result < 0) { perror("Unsandboxed loopback control failed"); return 1; }
    puts("Loopback control succeeded");
    return 0;
}
