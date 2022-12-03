CC=gcc
CFLAGS=-lm
DBFLAGS=-g

all: gdat_to_ld.c ld_writing.o GopherCAN_names.o gdat_to_ld.h ld_writing.h types.h GopherCAN_names.h
	$(CC) $(DBFLAGS) -o ld_converter ld_writing.o GopherCAN_names.o gdat_to_ld.c $(CFLAGS) 

ld_writing.o: ld_writing.c
	$(CC) $(DBFLAGS) -c ld_writing.c $(CFLAGS)

GopherCAN_names.o: GopherCAN_names.c
	$(CC) $(DBFLAGS) -c GopherCAN_names.c $(CFLAGS)

.PHONY: clean

clean:
	rm *.o ld_converter
