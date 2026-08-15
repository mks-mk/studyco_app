#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.h"

int main(void)
{
    char choice_buf[16];
    int user_menu_choice = 0;
    char source_file_path[512];

    // Display menu
    printf("============================================\n");
    printf("     Universal Studyco Data Parser Tool     \n");
    printf("============================================\n");
    printf("1. Parse Syllabus\n2. Parse Questions\n3. Parse Notes\n");
    printf("Enter choice (1-3): ");

    if (fgets(choice_buf, sizeof(choice_buf), stdin) == NULL) {
        fprintf(stderr, "Failed to read menu choice.\n");
        return 1;
    }
    if (sscanf(choice_buf, "%d", &user_menu_choice) != 1) {
        fprintf(stderr, "Invalid menu choice.\n");
        return 1;
    }

    printf("Enter input text file path: ");
    if (fgets(source_file_path, sizeof(source_file_path), stdin) == NULL) {
        fprintf(stderr, "Failed to read file path.\n");
        return 1;
    }
    // remove possible newline
    source_file_path[strcspn(source_file_path, "\r\n")] = '\0';

    FILE *source_file_stream = fopen(source_file_path, "r");
    if (!source_file_stream) {
        fprintf(stderr, "Error opening input file: %s\n", source_file_path);
        return 1;
    }

    FILE *json_output_stream = fopen("output_ready.json", "w");
    if (!json_output_stream) {
        fprintf(stderr, "Error creating output file 'output_ready.json'.\n");
        fclose(source_file_stream);
        return 1;
    }

    switch (user_menu_choice)
    {
        case 1:
            parse_syllabus(source_file_stream, json_output_stream);
            break;
        case 2:
            parse_questions(source_file_stream, json_output_stream);
            break;
        case 3:
            parse_notes(source_file_stream, json_output_stream);
            break;
        default:
            fprintf(stderr, "Invalid choice. Exiting.\n");
            break;
    }

    fclose(source_file_stream);
    fclose(json_output_stream);

    return 0;
}
