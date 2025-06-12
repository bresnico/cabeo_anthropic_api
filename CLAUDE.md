# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an R-based automated AMSTAR2 systematic review screening system that uses Anthropic's Claude API to evaluate research papers according to AMSTAR2 criteria. The system processes PDF files of systematic reviews and generates standardized evaluation reports.

## Core Architecture

The system follows a modular architecture with specialized function files:

- **Main Entry Point**: `amstar_screening.R` - Orchestrates the entire screening process
- **API Layer**: `functions/claude_api.R` - Handles Claude API interactions with retry logic and JSON validation
- **Evaluation Logic**: `functions/amstar_evaluation.R` - PDF text extraction and core evaluation workflow
- **Data Processing**: `functions/data_processing.R` - Results formatting and Excel export generation
- **Utilities**: `functions/utils.R` - Configuration validation, logging, and file management

## Configuration System

The system uses `config.yml` for all configuration:
- Anthropic API settings (model, tokens, timeout)
- Folder structure definitions
- Screening parameters (retry attempts, export options)
- Output file naming

**IMPORTANT**: The API key in config.yml is live and functional - handle with care.

## Key Workflows

1. **PDF Processing**: PDFs are extracted from `data/` folder, text is cleaned and truncated to 50,000 characters for API limits
2. **API Evaluation**: Each PDF text is sent to Claude with a structured AMSTAR2 prompt requesting JSON responses
3. **Data Transformation**: Claude's JSON responses are mapped to standardized Excel output format matching existing CSV structure
4. **Export Generation**: Creates main results file and optional detailed justifications file

## Development Commands

```r
# Run full screening process
source("amstar_screening.R")

# Setup project (install packages, create folders)
source("setup.R")

# Run validation checks
source("functions/utils.R")
validate_project_structure()
```

## Error Handling Strategy

The system implements comprehensive error handling:
- **API Retry Logic**: 3 attempts with configurable delays for Claude API calls
- **JSON Validation**: Strict validation of Claude responses with required field checking
- **Logging System**: Detailed logs in `logs/screening_log.txt` with timestamps and error levels
- **Graceful Degradation**: Individual PDF failures don't stop batch processing

## Data Flow

1. PDFs in `data/` → Text extraction → API evaluation → JSON response → Data transformation → Excel export to `results/`
2. All operations logged to `logs/` with different severity levels
3. Results follow existing CSV format with 16 AMSTAR2 items plus evaluation metadata

## Critical Implementation Details

- **Text Truncation**: 50K character limit to prevent API timeouts
- **JSON Response Format**: Claude responses are forced to start with structured JSON using assistant message prefilling
- **Item Mapping**: Complex mapping between Claude's item names and standardized AMSTAR2 numbering
- **Critical vs Non-Critical Items**: System distinguishes between critical (7) and non-critical (9) AMSTAR2 criteria for final evaluation scoring