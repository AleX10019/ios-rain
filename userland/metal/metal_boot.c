/*
 * rain: the Metal test at boot, without a shell. launchd starts it once (org.rain.metal-boot,
 * output through the kernel's /dev/null tee: boot with sweetnull=...,metal_boot,metal_props,
 * metal_drv_test). It runs "metal_props on"; only when the kernel took the switch (boot-arg
 * metal=1) does it run metal_drv_test. Its arguments come from boot-arg metal_test, split at
 * ':' (boot-args cannot hold spaces), e.g. metal_test=--bundle:--picture:10; default --bundle.
 * metal_test=- skips the test (Metal stays on for the system).
 */
#include <spawn.h>
#include <stdio.h>
#include <string.h>
#include <sys/sysctl.h>
#include <sys/wait.h>
#include <unistd.h>

extern char **environ;

static int
run(char *const argv[])
{
	pid_t pid;
	int status = -1;
	if (posix_spawn(&pid, argv[0], NULL, NULL, argv, environ) != 0) {
		printf("metal-boot: cannot start %s\n", argv[0]);
		return -1;
	}
	waitpid(pid, &status, 0);
	return WIFEXITED(status) ? WEXITSTATUS(status) : 128 + WTERMSIG(status);
}

int
main(void)
{
	char *props[] = { "/redwood/bin/metal_props", "on", NULL };
	char *test[16] = { "/redwood/bin/metal_drv_test", "--bundle", NULL };
	char args[1024] = "";
	size_t size = sizeof(args) - 1;
	char *at;

	setvbuf(stdout, NULL, _IOLBF, 0);
	if (sysctlbyname("kern.bootargs", args, &size, NULL, 0) == 0 &&
	    (at = strstr(args, "metal_test=")) != NULL && (at == args || at[-1] == ' ')) {
		char *value = at + strlen("metal_test="), *word;
		int n = 1;
		value[strcspn(value, " ")] = '\0';
		while (n < 15 && (word = strsep(&value, ":")) != NULL) {
			if (*word != '\0') {
				test[n++] = word;
			}
		}
		test[n] = NULL;
	}
	sleep(20);      /* after SpringBoard is up: a test that aborts must not race the boot */
	int r = run(props);
	if (r != 0) {
		printf("metal-boot: metal_props on -> %d (no metal=1?), test skipped\n", r);
		return 0;
	}
	if (test[1] != NULL && strcmp(test[1], "-") == 0) {
		printf("metal-boot: Metal on, test skipped (metal_test=-)\n");
		return 0;
	}
	printf("metal-boot: running metal_drv_test");
	for (int i = 1; test[i] != NULL; i++) {
		printf(" %s", test[i]);
	}
	printf("\n");
	printf("metal-boot: metal_drv_test -> %d\n", run(test));
	return 0;
}
