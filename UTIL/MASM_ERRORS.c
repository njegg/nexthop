#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <wchar.h>


void create_line_links(FILE*);

/*
 *  Read the log and return the number of severe errors
 *
 *  After that: replace FILE.ASM(line_number) with FILE.ASM:line_number
 *  if make is run from vscode terminal, that will be a link
 *  to a error in a file
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
            sscanf(buf, "%i", &errors);
            break;
        }
    }

    if (errors == -1) {
        printf("Unable to check for errors from MASMLOG.TXT");
        fclose(fr);
        return 1;
    }

    rewind(fr);

    char c;
    while ((c = fgetc(fr)) != EOF) {
        if (c == '(') {
            fseek(fr, -1, SEEK_CUR);
            fputc(':', fr);
            fscanf(fr, "%[^\n]s", buf);
        }
    }

    fclose(fr);
    return errors;
}

void create_line_links(FILE* fr)
{
}
