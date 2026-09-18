#pragma once
#include <stdbool.h>
#include <stdint.h>
#include <sys/types.h>

// Main-thread only. A first request schedules icon work and returns false;
// output parameters remain unchanged until a colourway is ready. Authored
// app rules always win. pid is the actual owner of the target window.
bool knit_auto_yarn(const char* app, pid_t pid, uint32_t* yarn, int* chart);
// Completion on the main thread; redraw surviving windows owned by this PID.
void knit_auto_yarn_ready(pid_t pid);
