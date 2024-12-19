all: main

main: ./objetos
	@ gcc ./fonte/main.c -c -o ./objetos/main.o
	@ as ./fonte/leitura_f.s -o ./objetos/leitura_f.o
	@ gcc ./objetos/main.o ./objetos/leitura_f.o -o main

./objetos:
	@ mkdir objetos

clean:
	@ rm -r ./objetos
	@ rm main