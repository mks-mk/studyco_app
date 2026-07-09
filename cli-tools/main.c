#include<stdio.h>
#include<stdlib.h>
#include "parser.h"

int main()
{
    int user_menu_choice;
    char source_file_path[100];
    
    while(1)
    {
        printf("\n\n");
        //Display menu
        printf("============================================\n");
        printf("     Universal Studyco Data Parser Tool     \n");
        printf("============================================\n");
        printf("1. Parse Syllabus\n2. Parse Questions\n3. Parse Notes\n4. Exit\n");
        printf("Enter choice (1-4): ");
        
        scanf("%d", &user_menu_choice);
        if(user_menu_choice == 4)
        {
            printf("Exited Successfully\n");
            return 0;
        }
        if(user_menu_choice < 1 || user_menu_choice > 4)
        {
            printf("Invalid choice ! \n");
            continue;
        }
        printf("Enter input text file path: ");
        scanf("%s", source_file_path);

        FILE *source_file_stream = fopen(source_file_path, "r");
        FILE *json_output_stream = fopen("output_ready.json", "w");

        if(!source_file_stream || !json_output_stream )
        {
            printf("Error managing file streams. Make sure the input file exists!\n");
            if(source_file_stream)
            {
                fclose(source_file_stream);
            }
            if(json_output_stream)
            {
                fclose(json_output_stream);
            }
            continue;
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

    }
}
