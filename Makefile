liblua:
	gcc -c lua/*.c
	ar rcs liblua *.o
	rm *.o

build: liblua
	gcc -O2 -shared -static -o MyPlugin.dll plugin.c liblua -lgdi32 -luser32 \
	    -Wl,--add-stdcall-alias \
	    -ffunction-sections -fdata-sections

install: build
	cp MyPlugin.dll "/c/Program Files (x86)/RDS Spy/plugins"