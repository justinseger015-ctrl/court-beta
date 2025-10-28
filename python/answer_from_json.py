"""
Answer user questions about documents using extracted JSON facts.

This script implements the FACT_GUARD principle by answering questions
ONLY from verified, extracted facts stored in the database. This prevents
hallucinations and ensures consistency with the initial summarization.

Usage:
    python answer_from_json.py --doc_uid=<UUID> --prompt="User question here"

Output:
    JSON object with response_text, cited_fields, model_name, etc.

Requirements:
    - pyodbc (SQL Server connection)
    - google-generativeai (Gemini API)

Author: DocketWatch Team
Date: 2025-01-28
"""

import os
import sys
import json
import time
import argparse
import traceback
from typing import Dict, Any, List, Optional

# Fix Windows console encoding for Unicode characters
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except AttributeError:
        # Python < 3.7
        import codecs
        sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')
        sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'strict')

# Redirect print statements to stderr to keep stdout clean for JSON only
original_stdout = sys.stdout
sys.stdout = sys.stderr

# Import dependencies
try:
    import pyodbc
    import google.generativeai as genai
    IMPORTS_OK = True
except ImportError as e:
    IMPORTS_OK = False
    IMPORT_ERROR = str(e)

# Restore stdout for final JSON output
sys.stdout = original_stdout


def get_database_connection():
    """
    Establish connection to SQL Server.

    Returns:
        pyodbc.Connection object

    Raises:
        Exception if connection fails
    """
    conn_str = (
        "DRIVER={SQL Server};"
        "SERVER=localhost;"  # Update with actual server name
        "DATABASE=docketwatch;"
        "Trusted_Connection=yes;"
    )

    try:
        conn = pyodbc.connect(conn_str, timeout=10)
        return conn
    except pyodbc.Error as e:
        print(f"Database connection error: {e}", file=sys.stderr)
        raise


def load_document_json(doc_uid: str) -> Dict[str, Any]:
    """
    Load extracted JSON facts from database for given document.

    Args:
        doc_uid: Document UUID

    Returns:
        Dictionary with extracted fields from summary_ai_extraction_json

    Raises:
        ValueError: If document not found or has no extraction JSON
        Exception: For database errors
    """
    print(f"Loading extraction JSON for doc_uid: {doc_uid}", file=sys.stderr)

    conn = get_database_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""
            SELECT
                doc_uid,
                pdf_title,
                summary_ai_extraction_json,
                ocr_text
            FROM docketwatch.dbo.documents
            WHERE doc_uid = ?
        """, (doc_uid,))

        row = cursor.fetchone()

        if not row:
            raise ValueError(f"Document not found: {doc_uid}")

        # Extract fields
        doc_uid_db = str(row[0]) if row[0] else None
        pdf_title = row[1] if row[1] else "Unknown Document"
        extraction_json = row[2] if row[2] else None
        ocr_text = row[3] if row[3] else ""

        if not extraction_json:
            raise ValueError(f"No extraction JSON found for document: {pdf_title}")

        # Parse JSON
        try:
            extraction = json.loads(extraction_json)
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in extraction: {e}")

        print(f"Loaded extraction with {len(extraction)} top-level fields", file=sys.stderr)

        # Return both extraction and metadata
        return {
            "extraction": extraction,
            "doc_uid": doc_uid_db,
            "pdf_title": pdf_title,
            "ocr_length": len(ocr_text)
        }

    finally:
        cursor.close()
        conn.close()


def get_gemini_api_key() -> Optional[str]:
    """
    Retrieve Gemini API key from database utilities table.

    Returns:
        API key string or None if not found
    """
    try:
        conn = get_database_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT value
            FROM docketwatch.dbo.utilities
            WHERE name = 'GeminiApiKey'
        """)

        row = cursor.fetchone()
        cursor.close()
        conn.close()

        if row and row[0]:
            return row[0]
        else:
            print("Warning: GeminiApiKey not found in utilities table", file=sys.stderr)
            return None

    except Exception as e:
        print(f"Error retrieving API key: {e}", file=sys.stderr)
        return None


def answer_from_facts(extraction: Dict[str, Any], user_question: str, doc_title: str = "") -> Dict[str, Any]:
    """
    Use Gemini to answer question based ONLY on extracted facts.

    This implements the FACT_GUARD principle by:
    1. Providing only the extraction JSON (not raw OCR)
    2. Explicitly instructing the model to cite sources
    3. Rejecting questions outside the scope of facts

    Args:
        extraction: Dictionary of extracted fields
        user_question: User's natural language question
        doc_title: Optional document title for context

    Returns:
        Dictionary with:
            - response_text: AI's answer
            - cited_fields: List of field paths referenced
            - model_name: Model used
            - processing_ms: Time taken
            - tokens_input: Input token count
            - tokens_output: Output token count
            - error: Error message if failed
    """
    t_start = time.time()

    try:
        # Configure Gemini
        api_key = get_gemini_api_key()
        if not api_key:
            # Try environment variable as fallback
            api_key = os.environ.get("GEMINI_API_KEY")

        if not api_key:
            return {
                "response_text": "Error: Gemini API key not configured",
                "cited_fields": [],
                "model_name": "gemini-2.5-flash",
                "processing_ms": 0,
                "tokens_input": 0,
                "tokens_output": 0,
                "error": "API key not found"
            }

        genai.configure(api_key=api_key)
        model = genai.GenerativeModel("gemini-2.5-flash")

        # Build system prompt with FACT_GUARD enforcement
        doc_context = f"\n\nDocument Title: {doc_title}" if doc_title else ""

        system_prompt = f"""You are a legal document assistant helping users understand court documents. Answer the user's question using ONLY the provided extracted facts from the document.

{doc_context}

CRITICAL RULES:
1. Answer ONLY from the provided JSON facts below - do NOT invent or assume information
2. If the facts don't contain the answer, respond with: "This information is not available in the extracted facts."
3. Cite which field(s) you used by referencing the JSON path (e.g., "According to fields.settlement_amount...")
4. Keep answers concise, factual, and directly relevant to the question
5. Never speculate, make assumptions, or use external knowledge
6. If a field is null or empty, acknowledge that the information wasn't captured

Extracted Facts (JSON):
```json
{json.dumps(extraction, indent=2, ensure_ascii=False)}
```

User Question: {user_question}

Provide a clear, concise answer. If you cite specific facts, reference their JSON field paths."""

        print(f"Sending prompt to Gemini (input ~{len(system_prompt)} chars)", file=sys.stderr)

        # Call Gemini API
        response = model.generate_content(
            system_prompt,
            generation_config=genai.types.GenerationConfig(
                temperature=0.2,  # Lower temperature for more factual responses
                top_p=0.8,
                top_k=40,
                max_output_tokens=1000,
            )
        )

        response_text = response.text.strip()
        print(f"Received response ({len(response_text)} chars)", file=sys.stderr)

        # Extract cited fields from response
        cited_fields = extract_citations(response_text, extraction)

        processing_ms = int((time.time() - t_start) * 1000)

        # Get token counts if available
        try:
            tokens_input = response.usage_metadata.prompt_token_count
            tokens_output = response.usage_metadata.candidates_token_count
        except AttributeError:
            tokens_input = 0
            tokens_output = 0

        return {
            "response_text": response_text,
            "cited_fields": cited_fields,
            "model_name": "gemini-2.5-flash",
            "processing_ms": processing_ms,
            "tokens_input": tokens_input,
            "tokens_output": tokens_output,
            "error": None
        }

    except Exception as e:
        print(f"Error in answer_from_facts: {e}", file=sys.stderr)
        print(traceback.format_exc(), file=sys.stderr)

        processing_ms = int((time.time() - t_start) * 1000)

        return {
            "response_text": f"Error generating answer: {str(e)}",
            "cited_fields": [],
            "model_name": "gemini-2.5-flash",
            "processing_ms": processing_ms,
            "tokens_input": 0,
            "tokens_output": 0,
            "error": str(e)
        }


def extract_citations(response_text: str, extraction: Dict[str, Any]) -> List[str]:
    """
    Extract field paths that were likely cited from the response.

    This is a heuristic approach that looks for:
    1. Explicit field path mentions (e.g., "fields.settlement_amount")
    2. Values from the extraction that appear in the response

    Args:
        response_text: AI's response text
        extraction: The extraction dictionary

    Returns:
        List of field paths (e.g., ["fields.settlement_amount", "fields.filing_date_iso"])
    """
    cited = []
    response_lower = response_text.lower()

    def check_field(path: str, value: Any, depth: int = 0):
        """Recursively check if field value appears in response."""
        # Limit recursion depth to prevent issues with deeply nested structures
        if depth > 5:
            return

        # Check for explicit field path mention
        field_mention = path.lower()
        if field_mention in response_lower:
            cited.append(path)
            return

        # Check if value appears in response
        if isinstance(value, str) and len(value) > 3:
            # Only check substantial strings (not "N/A", "yes", etc.)
            if value.lower() in response_lower:
                cited.append(path)
        elif isinstance(value, (int, float)):
            # Check numeric values
            if str(value) in response_text:
                cited.append(path)
        elif isinstance(value, dict):
            # Recursively check nested dicts
            for k, v in value.items():
                check_field(f"{path}.{k}", v, depth + 1)
        elif isinstance(value, list):
            # Check list items
            for i, item in enumerate(value):
                if isinstance(item, str) and len(item) > 3:
                    if item.lower() in response_lower:
                        cited.append(path)
                        break  # Don't add multiple times for the same list
                elif isinstance(item, dict):
                    # For lists of dicts, check each dict
                    check_field(f"{path}[{i}]", item, depth + 1)

    # Check all top-level fields
    for key, val in extraction.items():
        check_field(f"fields.{key}", val)

    # Remove duplicates while preserving order
    seen = set()
    cited_unique = []
    for field in cited:
        if field not in seen:
            seen.add(field)
            cited_unique.append(field)

    print(f"Extracted {len(cited_unique)} citations: {cited_unique}", file=sys.stderr)

    return cited_unique


def main():
    """Main CLI entry point."""
    # Keep stdout redirected to stderr during argument parsing
    temp_stdout = sys.stdout
    sys.stdout = sys.stderr

    # Check imports
    if not IMPORTS_OK:
        error_result = {
            "response_text": "Error: Required dependencies not installed",
            "cited_fields": [],
            "model_name": "gemini-2.5-flash",
            "processing_ms": 0,
            "tokens_input": 0,
            "tokens_output": 0,
            "error": f"Import error: {IMPORT_ERROR}"
        }
        sys.stdout = temp_stdout
        print(json.dumps(error_result, ensure_ascii=False, indent=2))
        sys.exit(1)

    parser = argparse.ArgumentParser(
        description="Answer questions about documents using extracted JSON facts"
    )
    parser.add_argument(
        "--doc_uid",
        required=True,
        help="Document UUID"
    )
    parser.add_argument(
        "--prompt",
        required=True,
        help="User's question about the document"
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug output to stderr"
    )

    args = parser.parse_args()

    try:
        # Validate prompt length
        if len(args.prompt) > 1000:
            raise ValueError("Prompt too long (maximum 1000 characters)")

        if len(args.prompt.strip()) < 3:
            raise ValueError("Prompt too short (minimum 3 characters)")

        # Load extraction JSON from database
        doc_data = load_document_json(args.doc_uid)
        extraction = doc_data["extraction"]
        doc_title = doc_data["pdf_title"]

        if args.debug:
            print(f"Document: {doc_title}", file=sys.stderr)
            print(f"Extraction fields: {list(extraction.keys())}", file=sys.stderr)

        # Answer question using extracted facts
        print(f"Processing question: {args.prompt[:100]}...", file=sys.stderr)
        result = answer_from_facts(extraction, args.prompt, doc_title)

        # Add doc_uid to result
        result["doc_uid"] = args.doc_uid

        # Restore stdout for JSON output
        sys.stdout = temp_stdout

        # Output JSON to stdout (consumed by ColdFusion)
        print(json.dumps(result, ensure_ascii=False, indent=2))

        # Exit with success
        sys.exit(0)

    except ValueError as e:
        # Validation errors
        error_result = {
            "response_text": str(e),
            "cited_fields": [],
            "model_name": "gemini-2.5-flash",
            "processing_ms": 0,
            "tokens_input": 0,
            "tokens_output": 0,
            "error": str(e)
        }

        print(f"Validation error: {e}", file=sys.stderr)
        sys.stdout = temp_stdout
        print(json.dumps(error_result, ensure_ascii=False, indent=2))
        sys.exit(1)

    except Exception as e:
        # Unexpected errors
        tb = traceback.format_exc()
        error_result = {
            "response_text": f"Fatal error: {str(e)}",
            "cited_fields": [],
            "model_name": "gemini-2.5-flash",
            "processing_ms": 0,
            "tokens_input": 0,
            "tokens_output": 0,
            "error": f"{type(e).__name__}: {str(e)}",
            "traceback": tb if args.debug else None
        }

        print(f"Fatal error: {e}", file=sys.stderr)
        print(tb, file=sys.stderr)

        sys.stdout = temp_stdout
        print(json.dumps(error_result, ensure_ascii=False, indent=2))
        sys.exit(1)


if __name__ == "__main__":
    main()
