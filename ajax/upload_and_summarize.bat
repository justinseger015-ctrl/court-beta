@echo off
REM Batch wrapper for upload_and_summarize Python script
REM Called by upload_and_summarize.cfm
REM 
REM Usage: upload_and_summarize.bat <pdf_path> [extra_instructions]
REM   %1 = Full path to PDF file
REM   %2 = Optional extra instructions (quoted string)

setlocal

REM Python configuration
set PYTHON_EXE=C:\Program Files\Python312\python.exe
set PYTHON_SCRIPT=U:\docketwatch\python\summarize_upload_cli.py

REM Validate arguments
if "%~1"=="" (
    echo Error: No PDF file path provided
    exit /b 1
)

REM Build command with optional extra instructions
if "%~2"=="" (
    "%PYTHON_EXE%" "%PYTHON_SCRIPT%" --in "%~1"
) else (
    "%PYTHON_EXE%" "%PYTHON_SCRIPT%" --in "%~1" --extra "%~2"
)

REM Exit with Python's exit code
exit /b %ERRORLEVEL%
