# nexthop
## Work in progress

Small game writen in assembly for MASM assembler
'Inspired' by: https://kultisti.itch.io/lineoff

---

Process of compiling and running inside dosbox automated

You need MASM.EXE and LINK.EXE for dos inside UTIL dir 

running `$ make` will:
- run dosbox and try to compile
    - if  errors - print them to stdio and exit
    - if !errors - close dosbox and run a new one thet runs the game
