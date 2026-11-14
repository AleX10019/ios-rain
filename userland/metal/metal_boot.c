/*
 * rain: the Metal test at boot, without a shell. launchd starts it once (org.rain.metal-boot, output
 * on /dev/console = the USB log). It runs "metal_props on"; only when the kernel took the switch
 * (boot-arg metal=1) does it run "metal_drv_test --bundle". On any other boot it ends at once.
 */
#include <spawn.h>
#include <stdio.h>
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
	char *test[] = { "/redwood/bin/metal_drv_test", "--bundle", NULL };
	setvbuf(stdout, NULL, _IOLBF, 0);
	sleep(20);      /* after SpringBoard is up: a test that aborts must not race the boot */
	int r = run(props);
	if (r != 0) {
		printf("metal-boot: metal_props on -> %d (no metal=1?), test skipped\n", r);
		return 0;
	}
	printf("metal-boot: metal_drv_test --bundle -> %d\n", run(test));
	return 0;
}
