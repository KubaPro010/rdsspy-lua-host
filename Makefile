liblua:
	gcc -c lua/*.c
	ar rcs liblua *.o
	rm *.o
liblua-native:
	gcc -c lua/*.c -march=native
	ar rcs liblua.native *.o
	rm *.o

build: liblua
	gcc -O2 -shared -static -o luahost-x86.dll plugin.c liblua -lgdi32 -luser32 -lshell32 \
	    -Wl,--add-stdcall-alias \
	    -ffunction-sections -fdata-sections

build-native: liblua
	gcc -O2 -shared -static -o luahost.dll plugin.c liblua.native -lgdi32 -luser32 -lshell32 -march=native \
	    -Wl,--add-stdcall-alias \
	    -ffunction-sections -fdata-sections

install: build-native
	cp luahost.dll "/c/Program Files (x86)/RDS Spy/plugins"