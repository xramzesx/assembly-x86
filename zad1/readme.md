# Task 1 (`zad1`)

Simple calculator for numbers from range [0,9], typed in polish

![dosbox_calc](https://github.com/xramzesx/assembly-x86/assets/46059547/363a2b58-39e3-43c9-a6a8-ad53bfd6a966)

## Original assignment (in polish)

_Proszę napisać program będący słownym kalkulatorem realizującym trzy podstawowe działania: dodawanie, odejmowanie i mnożenie. 
Kalkulator powinien wykonywać słownie zapisane działanie (plus, minus, razy) na dwóch słownie zapisanych cyfrach (od zero do dziewięć).
Po uruchomieniu programu na ekranie w trybie tekstowym powinien pojawić się komunikat: "Wprowadź słowny opis działania" i po jego wprowadzeniu, w nowej linii powinien pojawić się słowny wynik._

_Przykłady wywołania Programu:_
```
> program1
Wprowadź słowny opis działania: trzy razy pięć
Wynikiem jest: piętnaście
```
```
> program1
Wprowadź słowny opis działania: osiem minus zero
Wynikiem jest: osiem
```
```
> program1
Wprowadź słowny opis działania: czy plus dwa
Błąd danych wejściowych!
```

## Running

To run this program, firstly you have to compile it (this step is described @ main readme.md). After that, 
make sure you are in the directory where the `main.exe` executable file is located before running the programs.

Task 1 uses DOS interrupt to get user input. To run this program type:

```
main
```

And pass a simple mathematical operation (in polish).
