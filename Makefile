CFILES = src/main.c src/parse.c src/mach.c src/hashtable.c src/events.c src/reconcile.c \
         src/windows.c src/border.c src/animation.c src/knit.c src/chart.c src/apps.c
LIBS = -framework AppKit -framework Cocoa -framework CoreVideo \
       -F/System/Library/PrivateFrameworks/ -framework SkyLight

.PHONY: all debug clean test preview catalogue bench

all: | bin
	clang -O3 -g -Isrc -fobjc-arc -c src/menubar.m -o bin/menubar.o
	clang -std=c99 -O3 -g -Isrc $(CFILES) bin/menubar.o -o bin/borders $(LIBS)

debug: | bin
	clang -O0 -g -Isrc -fobjc-arc -c src/menubar.m -o bin/menubar.o
	clang -std=c99 -O0 -g -DDEBUG -Isrc $(CFILES) bin/menubar.o -o bin/debug $(LIBS)

bin:
	mkdir bin

clean:
	rm -rf bin

bin/render-test: tests/render.c src/knit.c src/chart.c src/apps.c src/misc/knit.h src/misc/chart.h src/misc/apps.h tests/catalogue.h | bin
	clang -std=c99 -O3 -Isrc tests/render.c src/knit.c src/chart.c src/apps.c -framework ApplicationServices -framework CoreText -o $@

test: bin/render-test
	clang -std=c99 -O1 -g -fsanitize=address,undefined -Isrc tests/tracking.c src/animation.c -o bin/tracking-test $(LIBS)
	bin/tracking-test
	clang -std=c99 -O1 -g -fsanitize=address,undefined -Isrc tests/events.c src/hashtable.c -o bin/events-test $(LIBS)
	bin/events-test
	clang -O1 -g -fobjc-arc -fsanitize=address,undefined -Isrc tests/reconcile.m src/hashtable.c -o bin/reconcile-test $(LIBS)
	bin/reconcile-test
	clang -std=c99 -Wall -Wextra -Werror -fsanitize=address -g -Isrc tests/collection_test.c src/apps.c src/chart.c -o bin/collection-test -framework ApplicationServices
	bin/collection-test
	bin/render-test
	clang -std=c99 -O1 -g -fsanitize=address,undefined -Isrc tests/ax_focus.c -framework ApplicationServices -o bin/ax-focus-test
	bin/ax-focus-test
	clang -std=c99 -O1 -g -fobjc-arc -fsanitize=address,undefined -Isrc tests/menu.m -framework Cocoa -o bin/menu-test
	bin/menu-test

# Optional native integration probe: build only. Running it creates its own
# temporary window; keep it out of unattended unit tests.
bin/live-resize: tests/live_resize.m src/border.c src/border.h src/knit.c src/chart.c src/apps.c | bin
	clang -O2 -g -fobjc-arc -Isrc tests/live_resize.m src/animation.c src/knit.c src/chart.c src/apps.c -o $@ $(LIBS)

bin/live-order: tests/live_order.m tests/live_resize.m src/border.c src/border.h src/knit.c src/chart.c src/apps.c | bin
	clang -O2 -g -fobjc-arc -Isrc tests/live_order.m src/animation.c src/knit.c src/chart.c src/apps.c -o $@ $(LIBS)

preview: bin/render-test
	mkdir -p outputs
	bin/render-test outputs/collection-preview.png

catalogue: bin/render-test
	mkdir -p docs/collection
	bin/render-test --catalogue docs/collection
	bin/render-test --classics docs/collection
	bin/render-test --individual docs/collection

bench: bin/render-test
	bin/render-test --bench

# Optional owned-window display handoff probe; --list is read-only.
bin/live-display: tests/live_display.m tests/live_resize.m src/border.c src/border.h src/knit.c src/chart.c src/apps.c | bin
	clang -O2 -g -fobjc-arc -Isrc tests/live_display.m src/animation.c src/knit.c src/chart.c src/apps.c -o $@ $(LIBS)
