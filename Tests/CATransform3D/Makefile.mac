
all: catransform3d

catransform3d.o: ../Testing.h

catransform3d: catransform3d.o ../Testing.h
	$(CC) catransform3d.o -o catransform3d -framework QuartzCore && ./catransform3d

clean:
	-rm catransform3d.o catransform3d
