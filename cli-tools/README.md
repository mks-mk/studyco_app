# Academic Content to JSON Parser Engine

A command-line utility written in C that converts academic content such as syllabi, question papers, and study notes into structured JSON.

It helps transform raw university documents (for example, KTU content) into JSON that can be used in applications like Flutter and Firebase.

---

## Features

- **Syllabus Parser**
  - Uses `calloc()` for dynamic memory allocation.
  - Handles large text blocks and paragraphs safely.
  - Prevents stack overflow issues.

- **Question Parser**
  - Uses a custom `is_sub_question()` function.
  - Detects sub-questions such as `a)`, `b)`, `c)`.
  - Detects normal question formats like `Q.1`.

- **Notes Parser**
  - Reads pipe-separated (`|`) text lines.
  - Converts data into JSON objects with:
    - `title`
    - `author`
    - `url`

- **JSON Validation**
  - Removes unwanted newline characters (`\n`).
  - Handles commas correctly.
  - Produces valid JSON output.

---

## Project Structure

```text
├── main.c
├── parser_modules.c
└── README.md
```

- `main.c` → Menu system and file handling.
- `parser_modules.c` → Parsing logic and helper functions.
- `README.md` → Documentation.

---

## Input File Rules

### 1. Syllabus Files

- Every module must start with `Module` or `module`.
- A colon (`:`) must separate the module name and topics.
- Any line that does not start with `Module` is added to the current module text.

**Example**

```text
Module 1: Memory Architecture inside C
Introduction to stack memory layout.
Differentiate between malloc and calloc allocations.
```

---

### 2. Question Files

- Main questions must start with:
  - `Q.`
  - `Question`

- Sub-questions must start with:
  - `a)`
  - `b)`
  - `A)`
  - `B)`

- Leading spaces are ignored.

**Example**

```text
Q.1 Explain memory management patterns.
   a) Define the concept of heap allocation.
   b) What is a memory leak?
```

---

### 3. Notes Files

- Fields must be separated using `|`.
- Format:

```text
Title | Author | Resource URL
```

- Leave one space before and after `|` for better parsing.

**Example**

```text
Systems Programming Guide | Tech Team | https://studyco.dev/systems-c.pdf
```

---

## Compilation and Execution (WSL / GCC)

### Go to Project Folder

```bash
cd /path/to/your/project_folder
```

### Compile

```bash
gcc main.c parser_modules.c -o run
```

This creates an executable file named `run`.

### Run

```bash
./run
```

Choose the parser mode from the menu and enter the input file name (for example, `syllabus_test.txt`).

---

## Examples

### Syllabus Parser

**Input**

```text
Module 1: Memory Architecture inside C
Introduction to stack memory layout.
Differentiate between malloc and calloc allocations.
```

**Output**

```json
{
  "type": "syllabus",
  "data": {
    "Module 1": "Memory Architecture inside C Introduction to stack memory layout. Differentiate between malloc and calloc allocations."
  }
}
```

---

### Question Parser

**Input**

```text
Q.1 Explain memory management patterns.
   a) Define the concept of heap allocation.
   b) What is a memory leak?
```

**Output**

```json
{
  "type": "questions",
  "list": [
    "Q.1 Explain memory management patterns.",
    "a) Define the concept of heap allocation.",
    "b) What is a memory leak?"
  ]
}
```

---

### Notes Parser

**Input**

```text
Systems Programming Guide | Tech Team | https://studyco.dev/systems-c.pdf
```

**Output**

```json
{
  "type": "notes",
  "list": [
    {
      "title": "Systems Programming Guide",
      "author": "Tech Team",
      "url": "https://studyco.dev/systems-c.pdf"
    }
  ]
}
```

---

## Use Cases

- Convert syllabus documents to JSON.
- Parse exam question banks.
- Convert study notes into structured datasets.
- Prepare data for Flutter, React, Web, and Firebase projects.
- Build educational content pipelines.

---

## License

Open-source. You can modify, extend, and use it in educational or research projects.
