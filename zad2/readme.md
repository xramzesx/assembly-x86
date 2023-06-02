# Task 2 (`zad2`)

Ellipse drawing program in VGA 320x200 256-color mode, which uses keyboard input to control size and color of the ellipse and the background. 

![dosbox_ellipse](https://github.com/xramzesx/assembly-x86/assets/46059547/81e45a84-6864-4d9b-83cc-8e30d447dea6)


## Original assignment (in polish)

_Proszę napisać program uruchamiany z parametrami będącymi dwoma liczbami całkowitych z przedziału (od 0 do 200), 
reprezentującymi dwie osie (średnice) elipsy: wielką i małą. Następnie, program powinien stabilnie wyświetlić na 
ekranie w trybie graficznym "VGA: 320x200 256-kolorów" odpowiednią elipsę. Klawisze ze strzałkami powinny umożliwiać 
dynamiczną zmianę długości osi, a program na bieżąco powinien wówczas aktualizować wygląd elipsy na ekranie. 
Klawisze: "gór-dół" powinny zmieniać oś pionową, a klawisze: "lewo-prawo" oś poziomą. Wciśnięcie klawisza "Esc", 
powinno poprawnie zakańczać program._


_Przykłady wywołania Programu:_
```
> program2 150 40
```
 
```
> program2 200 120
```

## Controls

| Keys                      | Description                                       |
|---------------------------|---------------------------------------------------|
| Arrows:  `bottom` & `up`  | Change ellipse width (decrease & increase)        |
| Arrows:  `left` & `right` | Change ellipse height (decrease & increase)       |
| `Space`                   | Next ellipse color                                |
| `W` & `S`                 | Change ellipse color (previous & next)            |
| `A` & `D`                 | Change background color (previous & next)         |
| `Q`                       | Turn on/off screen cleaning after ellipse drawing |
| `Esc`                     | Exit program                                      |

## Running

To run this program, firstly you have to compile it (this step is described @ main readme.md). After that, 
make sure you are in the directory where the `main.exe` executable file is located before running the programs.

Task 2 uses PSP (Program Segment Prefix). To run this program, type:

```
main <width> <height>
```
