//This folder contains the function prototypes


#ifndef PARSER_H
#define PARSER_H
#include <stdio.h>

char *trim_spaces(char *str);  //to clean the text strings 
void parse_syllabus(FILE *input_file, FILE *output_file); //to turn a raw module into JSON key value map
void parse_questions(FILE *input_file, FILE *output_file); //to extract clean exam Qns into a JSON array list
void parse_notes(FILE *input_file, FILE *output_file); //to convert links into grouped JSON data objects

#endif //PARSER_H
