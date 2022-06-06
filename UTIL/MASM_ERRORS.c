#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <wchar.h>


void create_line_links(FILE*);

/*
 *  Read the log and return the number of severe errors
 *  Used in makefile to not execute the program if there are
 *  errors
 *
 *  After that: replace FILE.ASM(line_number) with FILE.ASM:line_number
 *  This makes masm errors in terminal clickable if ran from vscode terminal
 *  When clicked, vscode will jump to line with error
 */
int main()
{
    FILE *fr = fopen("UTIL/MASMLOG.TXT", "r+");
    if (!fr) {
        perror("UTIL/MASMLOG.TXT");
        printf("Last compiled version of program will run\n");
        return 2;
    }

    char buf[256];
    char *needle;
    int errors = -1;
    while (fgets(buf, 256, fr)) {
        if (strstr(buf, "Severe  Errors")) {
            sscanf(buf, "%i", &errors); // get the number of errors from line
            break;
        }
    }

    // didnt find a line with errors
    if (errors == -1) {
        printf("Unable to check for errors from MASMLOG.TXT\n");
        fclose(fr);
        return 1;
    }

    rewind(fr);

    // replace .ASM(69 with .ASM:69 - makes it a link: file:line_number
    char c;
    while ((c = fgetc(fr)) != EOF) {
        if (c == '(') {
            fseek(fr, -1, SEEK_CUR);     // '(' found, go back to it
            fputc(':', fr);              // replace
            fscanf(fr, "%[^\n]s", buf);  // go to next line
        }
    }

    fclose(fr);
    return errors;
}
