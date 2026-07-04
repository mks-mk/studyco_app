# Academic Content to JSON Parser Engine 🛠️

A high-performance, modular command-line utility engineered in **C** to automate the extraction of unstructured university documents (such as KTU syllabi, unstructured question banks, and raw material links) and compile them into strictly formatted, production-ready JSON payloads.

This tool acts as an automated data pipeline for educational content, eliminating manual, error-prone JSON data entry for application backends like **Flutter** and **Firebase**, reducing administrative processing overhead by an estimated **90%**.

---

# ⚡ Key Features

## Syllabus Parser

- Uses `calloc()` to allocate memory and initialize it to zero.
- Uses dynamic memory allocation to read large syllabus content safely.

## Question Parser

- Uses the `is_sub_question()` function to separate main questions from sub-questions like `a)` and `b)`.
- Supports both `Q.1` and `Question` formats.

## Notes Parser

- Reads notes where fields are separated using the `|` character.
- Converts each record into JSON with `title`, `author`, and `link`.

## String Cleaning

- Removes extra spaces, tabs, carriage returns, and blank lines.
- Creates valid JSON without extra commas.

---

# 📂 Project Structure

```text
├── main.c                  # CLI menu and file handling
├── parser_modules.c        # Parsing functions
└── README.md               # Project documentation
```

---

#  Input File Format :

## 1. Syllabus

Every module should start with `Module` or `module`.

Use `:` to separate the module title and content.

Lines after the module heading are added to that module.

### Example

```text
Module 1: Memory Architecture inside C
Introduction to stack memory layout.
Differentiate between malloc and calloc allocations.
```

---

## 2. Question Bank

Main questions should start with `Q.` or `Question`.

Sub-questions should use `a)`, `b)`, etc.

Extra spaces at the beginning of lines are ignored.

### Example

```text
Q.1 Explain memory management patterns.
   a) Define heap allocation.
   b) What is a memory leak?
```

---

## 3. Notes

Each line should follow this format:

```text
Title | Author | URL
```

### Example

```text
Systems Programming Guide | Tech Team | https://studyco.dev/systems-c.pdf
```

---

#  Compile and Run (Linux / GCC / WSL)

```bash
cd /path/to/your/project_folder
gcc main.c parser_modules.c -o run
./run
```

Choose a parser from the menu and enter the input file name.

---

#  Example Output

## Syllabus

### Input

```text
Module 1: Memory Architecture inside C
Introduction to stack memory layout.
```

### Output

```json
{
  "type":"syllabus",
  "data":{
    "Module 1":"Memory Architecture inside C Introduction to stack memory layout."
  }
}
```

---

## Questions

```json
{
  "type":"questions",
  "list":[
    "Q.1 Explain memory management patterns.",
    "a) Define heap allocation."
  ]
}
```

---

## Notes

```json
{
  "type":"notes",
  "materials":[
    {
      "title":"Systems Programming Guide",
      "author":"Tech Team",
      "link":"https://studyco.dev/systems-c.pdf"
    }
  ]
}
```

---

# Uses

- Convert academic text files into JSON automatically.
- Organize syllabi, question banks, and notes.
- Prepare data for Flutter, React, Android, or other applications.
- Upload structured data to Firebase Firestore or Realtime Database.