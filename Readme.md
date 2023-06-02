# Assembly x86
This repository contains files and projects related to the Assembly x86 course at AGH University of Science and Technology.

### Task 1
![dosbox_calc](https://github.com/xramzesx/assembly-x86/assets/46059547/3935f2a9-85f7-4f3f-90c1-d91eaf7bfc85)

### Task 2
![dosbox_ellipse_homepage](https://github.com/xramzesx/assembly-x86/assets/46059547/fae261bd-fd6e-4422-99ec-56c8ed03d7ce)

## Setup
To build and run these projects you need to use DOSBox, an x86 emulator.

### Mount directory
First you need to mount project directory to the DOSBox emulator. To do this, open DOSBox and type:
```
mount C /path/to/project/directory
C:
```

### Compilation/Assembly
To compile/assemble programs, type:
```
ml <directory>/main.asm
```
Following that, ML creates `main.exe` executable file in the mounted directory 

## Running programs
Make sure you are in the directory where the `main.exe` executable file is located before running the programs.

### Task 1 (`zad1`)
Task 1 uses DOS interrupt to get user input, so to run this program type:
```
main
```
And pass a simple mathematical operation (in polish)

### Task 2 (`zad2`)
Task 2 uses PSP (Program Segment Prefix), so to run this program, type:
```
main <width> <height>
```
Where `width` and `height` refer to the ellipse total dimensions in pixels

## Additional links
- Documentation and other stuff for MASM Assembler [[link](https://github.com/qb40/masm/)]
