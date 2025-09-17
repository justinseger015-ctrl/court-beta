@echo off
setlocal enabledelayedexpansion

REM PDF Download Processor - Two Step Process
REM Step 1: Extract metadata 
REM Step 2: Download PDF file
REM Usage: pdf_download_processor.bat [case_event_id]

set CASE_EVENT_ID=%1
set PYTHON_DIR=u:\docketwatch\python
set PYTHON_EXE="C:\Program Files\Python312\python.exe"

if "%CASE_EVENT_ID%"=="" (
    echo ERROR: Case Event ID is required
    exit /b 1
)

echo Starting PDF download process for Case Event ID: %CASE_EVENT_ID%
echo.

REM Step 1: Extract metadata
echo [STEP 1] Running extract_pacer_pdf_metadata.py...
%PYTHON_EXE% "%PYTHON_DIR%\extract_pacer_pdf_metadata.py" %CASE_EVENT_ID%
set STEP1_RESULT=%errorlevel%

if %STEP1_RESULT% neq 0 (
    echo ERROR: Step 1 failed with exit code %STEP1_RESULT%
    exit /b %STEP1_RESULT%
)

echo [STEP 1] Metadata extraction completed successfully
echo.

REM Step 2: Download PDF file
echo [STEP 2] Running extract_pacer_pdf_file.py...
%PYTHON_EXE% "%PYTHON_DIR%\extract_pacer_pdf_file.py" %CASE_EVENT_ID%
set STEP2_RESULT=%errorlevel%

if %STEP2_RESULT% neq 0 (
    echo ERROR: Step 2 failed with exit code %STEP2_RESULT%
    exit /b %STEP2_RESULT%
)

echo [STEP 2] PDF download completed successfully
echo.
echo PDF download process completed successfully for Case Event ID: %CASE_EVENT_ID%

exit /b 0