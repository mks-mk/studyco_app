//This folder contains the functions and their codes



#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<ctype.h>   //to test and change individual characters
#include "parser.h" //link with parser.h file 



//function for removing unwanted spaces and tabs from a string
char *trim_spaces(char *str)
{
    char *end_position_index;

    //check string's starting position
    while( isspace((unsigned char)*str))
    {
        str++;
    }

    if( *str == 0)  //checking is the current *str is '\0' 
    {
        return str;
    }

    //check string's ending position
    else
    {
        end_position_index = str + strlen(str)-1;  //assigning index 
        while( end_position_index > str && isspace((unsigned char)*end_position_index))
        {
            end_position_index --;
        }
        end_position_index[1] = '\0';
        return str;
    }
}





//an helper function for 'parse_questions' function, checking if the qn is a sub qn or not
int is_sub_question(const char *str)
{
    //move a temperory pointer to the past of any blank space or a tab
    while( *str == ' ' || *str == '\t')
    {
        str ++;
    }
    
    //check if the current character is a letter b/w a-z OR A-Z
    //and ensure the very next character is a ')'
    if(((*str >= 'a' && *str<= 'z') || (*str >= 'A' && *str <= 'Z')) && *(str + 1) == ')' )
    {
        return 1;
    }
    else
    {
        return 0;
    }
}





        

//function for extracting only the exam Qns from a messy text file and turn them into a clean JSON list
void parse_questions(FILE *input_file, FILE *output_file)
{
    char *single_line ;  
    int max_line_size = 512;
    int is_the_very_first_qn = 1;      //for adding commas in json structure, bcs the elements are seperated by commas in a json structure
    int current_line_size=0;


    char *full_question_texts;
    int max_question_size = 2026;
    int full_question_length = 0;

    single_line = (char *)calloc(max_line_size , sizeof(char));      
    full_question_texts = (char *)calloc(max_question_size , sizeof(char));

    if(single_line == NULL || full_question_texts == NULL)
    {
        printf("System Error, Failed to allocate memory !\n");
        exit(1);
    }
    
    fprintf(output_file, "{\n \"type\": \"questions\",\n \"list\": [\n");  //writing the structure of JSON array header to the output file

    //read line by lines from the input file and store in allocated memory single_line
    while(fgets(single_line, max_line_size, input_file) != NULL)
    {

        current_line_size = strlen(single_line);
        
        while( current_line_size > 0 && single_line[current_line_size - 1] != '\n')
        {
            max_line_size *=2;
            char *resized_line;
            resized_line = realloc(single_line, max_line_size * sizeof(char));
            if(resized_line == NULL)
            {
                printf("SySystem Error, Failed to allocate memory\n");
                exit(1);
            }
            single_line = resized_line;

            //update fgets() to avoid overwrite
            if(fgets(single_line + current_line_size, max_line_size - current_line_size, input_file) == NULL)
            {
                break;
            }
            current_line_size = strlen(single_line);         
        }
        
        if( current_line_size > 0 && single_line[current_line_size - 1] == '\n')
        {

            single_line[current_line_size-1]='\0';
        }
        char *trimmed_question = trim_spaces(single_line);
        if(strlen(trimmed_question) == 0 )   //
        {
            continue;
        }

        if( strstr(trimmed_question, "Question.") || strstr(trimmed_question, "Q.") || is_sub_question(trimmed_question))
        {
            if(full_question_length > 0)  //checking if there is any qns exists on buffer, if yes, then first print it on the output file in correct way, bcz that's completed.
            {
                if(!is_the_very_first_qn)  // is_the_very_first_qn != 1
                {                          // ie, 1 != 1
                    fprintf(output_file, ",\n");
                }
            
                
                    fprintf(output_file, "  \"%s\"", full_question_texts);
                    is_the_very_first_qn = 0;
                
            }
            //clear the buffer
            strcpy(full_question_texts, trimmed_question);
            full_question_length = strlen(full_question_texts);
        }
        else
        {
            if( full_question_length > 0)
            {
                if(full_question_length + strlen(trimmed_question) + 2 >= max_question_size)  // +2 = +1 for the space " ", +1 for the null terminator '\0'
                {
                    max_question_size *=2;
                    char *resized_question = realloc( full_question_texts, max_question_size * sizeof(char));
                    if( resized_question == NULL)
                    {
                        printf("System Error, Failed to allocate memory\n");
                        exit(1);
                    }

                    full_question_texts = resized_question;
                }

                //continuation of the current question
                strcat(full_question_texts, " ");
                strcat(full_question_texts, trimmed_question);
                full_question_length = strlen(full_question_texts);
                
            }
        }
        
    }

    //print the final question remaining in the buffer
    if( full_question_length > 0 )   // Buffer contains the last question?
    {
        if(!is_the_very_first_qn)     // Already printed previous questions?
        {
            fprintf(output_file, ",\n");
        }

        fprintf(output_file, "  \"%s\"", full_question_texts);
    }


    fprintf(output_file, "\n ]\n}\n");
    
    free(single_line);
    free(full_question_texts);

    printf("░░░ Question Bank JSON generated successfully! ░░░\n");

}







//function to take a raw messy syllabus text file and organize it into a structured JSON dictionary
void parse_syllabus(FILE *input_file, FILE *output_file)
{
    char *line;
    int line_capacity = 256;
    int is_first_module = 1;   //used to print commas on JSON structures
    char module_name[64] = "";
    char *module_topics;
    int line_length = 0;

    line = (char *)malloc(line_capacity * sizeof(char));
    if (line == NULL)
    {
        printf("System Error, Failed to allocate memory!\n");
        exit(1);
    }

    module_topics = (char *)calloc(4096, sizeof(char));
    if (module_topics == NULL)
    {
        printf("System Error, Failed to allocate memory!\n");
        free(line);
        exit(1);
    }

    //write the structure of JSON array header
    fprintf(output_file, "{\n  \"type\": \"syllabus\",\n  \"data\": {\n");

    while (fgets(line, line_capacity, input_file) != NULL)
    {
        /* Read the complete line */
        line_length = strlen(line);

        while (line_length > 0 && line[line_length - 1] != '\n')
        {
            line_capacity *= 2;

            char *temp = realloc(line, line_capacity);
            if (temp == NULL)
            {
                free(line);
                free(module_topics);
                printf("System Error, Failed to reallocate memory!\n");
                exit(1);
            }

            line = temp;

            if (fgets(line + line_length,
                      line_capacity - line_length,
                      input_file) == NULL)
            {
                break;
            }

            line_length = strlen(line);
        }

        if (line_length > 0 && line[line_length - 1] == '\n')
        {
            line[line_length - 1] = '\0';
        }

        char *trimmed = trim_spaces(line);

        /* Module line must START with Module */
        if (strncmp(trimmed, "Module", 6) == 0 ||
            strncmp(trimmed, "module", 6) == 0)
        {
            if (strlen(module_name) > 0)
            {
                if (!is_first_module)
                {
                    fprintf(output_file, ",\n");
                }

                fprintf(output_file,
                        "    \"%s\": \"%s\"",
                        trim_spaces(module_name),
                        trim_spaces(module_topics));

                is_first_module = 0;
            }

            char *module_title;
            char *module_description;

            module_title = strtok(trimmed, ":");
            module_description = strtok(NULL, "");

            if (module_title != NULL)
            {
                strcpy(module_name, trim_spaces(module_title));

                if (module_description != NULL)
                {
                    strcpy(module_topics, trim_spaces(module_description));
                }
                else
                {
                    strcpy(module_topics, "");
                }
            }
        }
        else
        {
            if (strlen(module_name) > 0)
            {
                strcat(module_topics, " ");
                strcat(module_topics, trimmed);
            }
        }
    }

    if (strlen(module_name) > 0)
    {
        if (!is_first_module)
        {
            fprintf(output_file, ",\n");
        }

        fprintf(output_file,
                "    \"%s\": \"%s\"",
                trim_spaces(module_name),
                trim_spaces(module_topics));
    }

    fprintf(output_file, "\n  }\n}\n");

    printf("░░░ full Syllabus Paragraph JSON generated Successfully! ░░░\n");

    free(line);
    free(module_topics);
}




//function to take a raw list of download links and convert them into a structured list of JSON objects
void parse_notes(FILE *input_file, FILE *output_file)
{
    char line[512];
    int is_first_module = 1;

    fprintf(output_file, "{\n  \"type\": \"notes\", \n  \"materials\":[\n");
    while (fgets(line, sizeof(line), input_file) != NULL)
    {
        if(strstr(line, "|") != NULL)
        {
            char *note_title, *author_name, *download_link;

            note_title = strtok(line, "|");
            author_name = strtok(NULL, "|");
            download_link = strtok(NULL, "\n");

            if(note_title != NULL && author_name != NULL && download_link != NULL)
            {
                if (!is_first_module)
                {
                    fprintf(output_file, ",\n");
                }
                fprintf(output_file, "    {\n");
                fprintf(output_file, "    \"title\": \"%s\", \n", trim_spaces(note_title));
                fprintf(output_file, "    \"author\": \"%s\", \n", trim_spaces(author_name));
                fprintf(output_file, "    \"link\": \"%s\"\n", trim_spaces(download_link));
                fprintf(output_file, "    }");

                is_first_module = 0;
            }
        }
    }
    fprintf(output_file, "\n  ]\n}\n");
    printf("░░░ Notes Metadata JSON generated successfully! ░░░\n");
}

