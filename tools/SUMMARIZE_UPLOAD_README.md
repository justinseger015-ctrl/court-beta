# AI Summary Upload Tool

## Overview

A standalone DocketWatch tool for uploading PDF documents and generating AI-powered legal summaries with structured field extraction, verification, and QC feedback.

## Features

- **Drag-and-drop PDF upload** with file validation
- **OCR text extraction** (prefers embedded text, falls back to OCR)
- **Two-step AI summarization** with FACT_GUARD verification
- **Structured field extraction** (parties, dates, charges, dispositions, etc.)
- **Collapsible JSON viewer** for detailed analysis
- **QC feedback system** for quality control and continuous improvement
- **SHA-256 de-duplication** to prevent duplicate processing

## Architecture

### Frontend
- **`/tools/summarize_upload.cfm`** - Main UI with drag-drop interface
  - Drag-and-drop zone for PDF upload
  - Optional instructions textarea
  - Real-time processing status
  - Summary, OCR, and JSON display
  - QC feedback form

### Backend (CFML)
- **`/ajax/upload_and_summarize.cfm`** - Handles file upload and processing
  - Validates PDF files
  - Computes SHA-256 hash
  - Calls Python worker
  - Returns JSON response

- **`/ajax/save_qc_feedback.cfm`** - Saves QC feedback
  - Stores success/failure status
  - Captures user notes
  - Links to document or upload hash

### Python Worker
- **`/python/summarize_upload_cli.py`** - CLI processor
  - Accepts `--in <file>` and `--extra <instructions>`
  - Performs OCR extraction
  - Runs FACT_GUARD pipeline:
    1. Extract structured facts (JSON schema)
    2. Render summary from facts
    3. Verify summary against facts
  - Returns JSON output to stdout

### Database
- **`docketwatch.dbo.summary_qc_feedback`** - QC feedback table
  - Tracks success/failure rates
  - Captures user feedback
  - Links to documents via doc_uid or upload_sha256

## Usage

### Web Interface

1. Navigate to `/tools/summarize_upload.cfm`
2. Drag a PDF file or click to select
3. (Optional) Add extra instructions
4. Click "Generate AI Summary"
5. Review summary, OCR text, and structured fields
6. Provide QC feedback (success/failure + notes)

### Command Line (Python)

```bash
# Basic usage
python summarize_upload_cli.py --in "C:\path\to\document.pdf"

# With extra instructions
python summarize_upload_cli.py --in "C:\path\to\document.pdf" --extra "Focus on sentencing details"
```

### Output Format

```json
{
  "doc_uid": null,
  "model_name": "gemini-2.5-flash",
  "summary_text": "Plain text summary...",
  "summary_html": "<h3>EVENT SUMMARY</h3><p>...</p>",
  "ocr_text": "Extracted text from PDF...",
  "fields": {
    "doc_type": "Judgment",
    "filing_date_iso": "2025-10-16",
    "parties": {
      "plaintiff": "United States",
      "defendant": "John Doe",
      "others": []
    },
    "counts_convicted": [1, 3, 5],
    "sentence": {
      "imprisonment_months": 60,
      "supervised_release_years": 5,
      "fine_usd": 10000,
      "restitution_usd": 0
    }
  },
  "errors": [],
  "processing_ms": 15234,
  "upload_sha256": "abc123...",
  "verifier_result": "PASSED"
}
```

## Configuration

### Prerequisites

1. **Python 3.12+** installed at `C:\Python312\python.exe`
2. **Upload directory** created at `U:\docketwatch\uploads\`
3. **Gemini API key** configured in `docketwatch.dbo.utilities`
4. **Database table** created via `sql/create_summary_qc_feedback.sql`

### Environment Variables

- **`FACT_GUARD`** - Enable/disable verification pipeline (default: `true`)

### Python Dependencies

- `google-generativeai` - Gemini API
- `PyPDF2` - PDF text extraction
- `pdf2image` - PDF to image conversion
- `pytesseract` - OCR engine
- `opencv-python` - Image preprocessing
- `pyodbc` - Database connectivity
- `beautifulsoup4` - HTML parsing
- `markdown2` - Markdown to HTML

## Security

- **File validation**: Checks PDF magic bytes (`%PDF`)
- **Size limit**: 25 MB maximum
- **Upload isolation**: Files stored outside webroot
- **SQL injection protection**: All queries use `cfqueryparam`
- **Error handling**: Detailed logging, sanitized user output

## Testing

### Test Cases

1. **Native text PDF** - Document with embedded text layer
2. **Scanned PDF** - Image-based document requiring OCR
3. **Multi-page document** - Test OCR pagination
4. **Bad scan** - Skewed or low-quality image
5. **Extra instructions** - Verify instruction incorporation
6. **Error handling** - Corrupted PDF, timeout, API failure

### Manual Testing

```bash
# Test 1: Simple text PDF
python summarize_upload_cli.py --in "test_docs/simple.pdf"

# Test 2: With instructions
python summarize_upload_cli.py --in "test_docs/complex.pdf" --extra "Focus on financial terms"

# Test 3: Scanned document
python summarize_upload_cli.py --in "test_docs/scanned.pdf"
```

## Monitoring

### QC Metrics

Query success/failure rates:

```sql
SELECT 
    model_name,
    COUNT(*) as total_submissions,
    SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as successes,
    SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as failures,
    CAST(SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as success_rate
FROM docketwatch.dbo.summary_qc_feedback
WHERE created_at >= DATEADD(day, -30, GETDATE())
GROUP BY model_name
ORDER BY total_submissions DESC
```

### Common Issues in QC Notes

```sql
SELECT 
    notes,
    COUNT(*) as frequency
FROM docketwatch.dbo.summary_qc_feedback
WHERE success = 0
  AND notes IS NOT NULL
  AND created_at >= DATEADD(day, -30, GETDATE())
GROUP BY notes
ORDER BY frequency DESC
```

## Troubleshooting

### "Failed to parse Python output"

- Check Python stderr for errors
- Verify Python dependencies installed
- Check Gemini API key validity
- Review upload file permissions

### "OCR text too short"

- PDF may be image-based with poor quality
- Try increasing OCR DPI in Python config
- Check Tesseract installation

### "Verification failed"

- Summary contains claims not in extracted facts
- Review `verifier_notes` in response
- Check if extra instructions conflicted with facts

## Future Enhancements

- [ ] Batch upload support
- [ ] Document type classification
- [ ] Custom extraction templates by document type
- [ ] Side-by-side comparison with previous summaries
- [ ] Export to Word/PDF
- [ ] Integration with case tracking system
- [ ] Real-time collaboration/annotations

## Support

For issues or questions:
1. Check QC feedback database for similar cases
2. Review Python error logs in `U:\docketwatch\python\logs\`
3. Check CFML logs in ColdFusion admin

## License

Internal DocketWatch tool - proprietary use only.
