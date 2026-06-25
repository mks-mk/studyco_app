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



//an helper function for 'parse_questions' function
int is_sub_question(const char *str)
{
    //move a temperory pointer to the past of any blank space or a tab
    while( *str == ' ' || *str == '\t')
    {
        str ++;
    }
    
    //check if the current character is a letter b/w a-z OR A-Z
    //and ensure the very next character is a ')'
    if((*str >= 'a' && *str<= 'z') || (*str >= 'A' && *str <= 'Z') && *(str + 1) == ')' )
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
    char line_buffer[512]; //512 bytes is the safe here
    int is_first_item = 1;
    size_t len=0;
    
    //write the structure of JSON array header
    fprintf(output_file, "{\n \"type\": \"questions\",\n \"list\": [\n");
    
    while(fgets(line_buffer, sizeof(line_buffer), input_file) != NULL)
    {
        if( strstr(line_buffer, "Q.") != NULL || strstr(line_buffer, "Question") != NULL || is_sub_question(line_buffer))
        {
            len = strlen(line_buffer);
            if(len > 0 && line_buffer[len -1] == '\n')
            {
                line_buffer[len -1] = '\0';
            }
            if(!is_first_item)
            {
                fprintf(output_file, ",\n");
            }
            
            fprintf(output_file, "   \"%s\"", trim_spaces(line_buffer)); 

            is_first_item = 0;
        }
    }

    //close the JSON array formatting
    fprintf(output_file, "\n  ]\n}\n");
    printf("░░░ Question Bank JSON generated succesfully ! ░░░\n");
}



//function to take a raw messy syllabus text file and organize it into a structured JSON dictionary
void parse_syllabus(FILE *input_file, FILE *output_file)
{
    char line_buffer[256];
    int is_first_item = 1;
    char current_module[64]="";
    char *topic_accumulator;
    size_t len = 0;

    topic_accumulator =(char *)calloc(4096, sizeof(char));
    if( topic_accumulator == NULL)
    {
        printf("System Error, Failed to allocate memory !\n");
        exit(1);
    }

    //write the structure of JSON array header
    fprintf(output_file, "{\n  \"type\": \"syllabus\",\n  \"data\": {\n");
    
    while(fgets(line_buffer, sizeof(line_buffer), input_file) != NULL)
    {
        if(strstr(line_buffer, "Module") != NULL || strstr(line_buffer, "module") != NULL)
        {
            if (strlen(current_module) > 0)
            {
                if(!is_first_item)
                {
                    fprintf(output_file, ",\n");
                }
                fprintf(output_file, "    \"%s\": \"%s\"", trim_spaces(current_module), trim_spaces(topic_accumulator));
                is_first_item = 0;
            }
            char *module_token, *topics_token;
            
            module_token = strtok(line_buffer, ":");
            topics_token = strtok(NULL, "\n");

            if(module_token != NULL)
            {
                strcpy(current_module, module_token);
                if(topics_token != NULL)
                {
                    strcpy(topic_accumulator, topics_token);
                }
                else
                {
                    strcpy(topic_accumulator, "");
                }
            }
        }
        else
        {
            if (strlen(current_module) > 0)
            {
                len = strlen(line_buffer);
                if( len > 0 && line_buffer[len - 1] == '\n')
                {
                    line_buffer[len - 1] = '\0';
                }
                strcat(topic_accumulator, " ");
                strcat(topic_accumulator, line_buffer);
            }
        }
    }
    if (strlen(current_module) > 0)
    {
        if(!is_first_item)
        {
            fprintf(output_file, ",\n");
        }
        fprintf(output_file, "   \"%s\": \"%s\"", trim_spaces(current_module), trim_spaces(topic_accumulator));
    }
    fprintf(output_file, "\n }\n}\n");
    printf("░░░ full Syllabus Paragraph JSON generated Successfully! ░░░\n");
    
    free(topic_accumulator);
}




//function to take a raw list of download links and convert them into a structured list of JSON objects
void parse_notes(FILE *input_file, FILE *output_file)
{
    char line_buffer[512];
    int is_first_item = 1;

    fprintf(output_file, "{\n  \"type\": \"notes\", \n  \"materials\":[\n");
    while (fgets(line_buffer, sizeof(line_buffer), input_file) != NULL)
    {
        if(strstr(line_buffer, "|") != NULL)
        {
            char *title_token, *author_token, *link_token;

            title_token = strtok(line_buffer, "|");
            author_token = strtok(NULL, "|");
            link_token = strtok(NULL, "\n");

            if(title_token != NULL && author_token != NULL && link_token != NULL)
            {
                if (!is_first_item)
                {
                    fprintf(output_file, ",\n");
                }
                fprintf(output_file, "    {\n");
                fprintf(output_file, "    \"title\": \"%s\", \n", trim_spaces(title_token));
                fprintf(output_file, "    \"author\": \"%s\", \n", trim_spaces(author_token));
                fprintf(output_file, "    \"link\": \"%s\"\n", trim_spaces(link_token));
                fprintf(output_file, "    }");

                is_first_item = 0;
            }
        }
    }
    fprintf(output_file, "\n  ]\n}\n");
    printf("░░░ Notes Metadata JSON generated successfully! ░░░\n");
}

