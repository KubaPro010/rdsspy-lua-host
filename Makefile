liblua:
	gcc -c lua/*.c
	ar rcs liblua *.o
	rm *.o

build: liblua
	gcc -O2 -shared -static -o luahost.dll plugin.c liblua -lgdi32 -luser32 -lshell32 \
	    -Wl,--add-stdcall-alias \
	    -ffunction-sections -fdata-sections

install: build
	cp luahost.dll "/c/Program Files (x86)/RDS Spy/plugins"