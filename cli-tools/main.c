#include<stdio.h>
#include<stdlib.h>
#include "parser.h"

int main()
{
    int user_menu_choice;
    char source_file_path[100];

    //Display menu
    printf("============================================\n");
    printf("     Universal Studyco Data Parser Tool     \n");
    printf("============================================\n");
    printf("1. Parse Syllabus\n2. Parse Questions\n3. Parse Notes\n");
    printf("Enter choice (1-3): ");
    
    if(scanf("%d", &user_menu_choice) != 1)
    {
        return 1;
    }
    printf("Enter input text file path: ");
    scanf("%s", source_file_path);

    FILE *source_file_stream = fopen(source_file_path, "r");
    FILE *json_output_stream = fopen("output_ready.json", "w");

    if(!source_file_stream || !json_output_stream )
    {
        printf("Error managing file streams.\n");
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
            printf("Invalid choice\n");
            break;
    }

    fclose(source_file_stream);
    fclose(json_output_stream);

    return 0;
}
