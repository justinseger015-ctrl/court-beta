@echo off
echo Unfiled PDF Deletion Script
echo ===========================
echo.
echo This script will delete PDF files and database records for unfiled cases with "Removed" status.
echo It processes 10 records at a time.
echo.
echo WARNING: This will permanently delete files and database records!
echo.
set /p confirm="Are you sure you want to continue? (y/N): "
if /i not "%confirm%"=="y" goto :cancel

echo.
echo Starting deletion process...
echo.

REM Try to run with Python
python delete_unfiled_pdfs_simple.py
if %errorlevel% neq 0 (
    echo.
    echo Python execution failed. Trying with py command...
    py delete_unfiled_pdfs_simple.py
)

goto :end

:cancel
echo Operation cancelled.

:end
echo.
pause
