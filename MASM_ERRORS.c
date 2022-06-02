#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

/*
 * Read the log and return the number of severe errors
*/

int main()
{
    FILE *fr = fopen("MASMLOG.TXT", "r");
    if (!fr) {
        printf("Unable to read MASMLOG.TXT: %s\n", strerror(errno));
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
        return 1;
    }

    return errors;
}
