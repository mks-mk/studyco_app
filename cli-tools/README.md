# Academic Text to JSON Parser:

A lightweight Command-Line Interface (CLI) tool written in pure C that converts academic text files (such as question banks, syllabus documents, and notes) into structured JSON.

It uses only the C standard library (no external dependencies) and demonstrates string processing, file handling, dynamic memory allocation, and modular programming.

---

## Features:

- Parse question bank text into JSON
- Parse syllabus/module text into JSON
- Parse notes and resource links into JSON
- Interactive CLI menu
- Pure C implementation
- No external libraries required

---

## Prerequisites:

You only need:

- GCC compiler
- Terminal (Linux/macOS) or Windows PowerShell/WSL

---

# Input File Format:

## 1. Question Bank (`input_questions.txt`)

Each question should begin with `Q.`, `Question.`, or a sub-question such as `a)` or `b)`.

Example:

```text
Q. What is a pointer in C programming?
Question. Explain the primary differences between stack and heap memory.
a) Define the purpose of calloc().
b) Explain how realloc() handles buffer expansion.
```

---

## 2. Syllabus (`input_syllabus.txt`)

Each module should start with `Module` (or `module`) followed by a colon (`:`).

Example:

```text
Module 1: Basics of C Systems
Introduction to compilation, tokens, and basic data types.

Module 2: Dynamic Memory Architecture
Deep dive into pointers, dynamic arrays, calloc, and realloc.
```

---

## 3. Notes & Resources (`input_notes.txt`)

Each line should follow this format:

```text
Title | Author | Download Link
```

Example:

```text
C Pointer Guide | Prof. John Doe | https://example.com/pointers.pdf
Memory Management Notes | Tech Academy | https://example.com/memory_handling.pdf
```

---

# Build and Run:

## Compile

```bash
gcc main.c parser_modules.c -o parser
```

## Run

Linux/macOS

```bash
./parser
```

Windows PowerShell

```powershell
.\parser.exe
```

---

# Usage

When the program starts, you'll see:

```text
========================================
    Universal Studyco Data Parser Tool
========================================
1. Parse Question Bank Text
2. Parse Syllabus Text
3. Parse Notes & Links
4. Exit

Select an option (1-4):
```

### Steps:

1. Choose an option (1–3).
2. Enter the path to the input `.txt` file.
3. The program reads the file and generates a structured JSON output.

The output is saved as:

```text
output_ready.json
```

---

# Project Structure:

```text
├── main.c
├── parser_modules.c
├── parser.h
├── input_questions.txt
├── input_syllabus.txt
├── input_notes.txt
└── output_ready.json
```

---

# File Description:

| File | Description |
|------|-------------|
| `main.c` | CLI menu and program flow |
| `parser_modules.c` | Parsing logic and JSON generation |
| `parser.h` | Function declarations |
| `input_questions.txt` | Sample question bank input |
| `input_syllabus.txt` | Sample syllabus input |
| `input_notes.txt` | Sample notes/resource input |
| `output_ready.json` | Generated JSON output |

---

# Concepts Used:

- C Programming
- File Handling
- String Manipulation
- Dynamic Memory Allocation
- Pointer Arithmetic
- Modular Programming
- Command-Line Interface (CLI)
- JSON Formatting

---

