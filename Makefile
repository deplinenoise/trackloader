
FLOPPY=bin/test.adf
FILES=data/sugtest.raw data/sugtest.pal

all: bin out $(FLOPPY)

bin:
	mkdir bin

out:
	mkdir out

$(FLOPPY): out/bb.sum out/main.raw $(FILES)
	python make-adf.py $@ out/bb.sum out/main.raw $(FILES)

out/bb.sum: out/bb.out
	python sum-bootblock.py $< $@

out/bb.out: out/bootblock.o
	vlink -brawbin1 $< -o $@

out/bootblock.o: bootblock.asm
	vc -c $< -o $@

out/main.o: main.asm
	vc -c $< -o $@

out/main.raw: out/main.o
	vlink -brawbin1 $< -o $@

clean:
	rm -rf out bin
