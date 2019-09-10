///usr/bin/env sh $(dirname $0)/appcc.sh "$0" "$@"; exit $?
#include "app/app.inl"
#include "echo.h"

int main(int argc, const char* argv[], const char* envp[]) {
    for (const char** arg = argv; *arg; ++arg) echo(*arg);
    for (const char** env = envp; *env; ++env) echo(*env);

    // app_cursor_set(APP_CURSOR_CROSSHAIR);
    app_window* window = app_window_acquire();
    app_window_activate(window);
    app_window_set_title(window, "app");

    void update();
    while (app_update() and app_window_is_open(window)) update();

    app_window_release(window);
    return 0;
}

void update() {
    /* cool */
}
