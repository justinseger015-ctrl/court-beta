# Interactive Q&A Enhancement - Implementation Checklist

**Project:** Summarize Upload Tool Enhancement
**Start Date:** TBD
**Target Completion:** ~5 weeks
**Developer:** [Assign Name]

---

## Quick Start

1. Read: `SUMMARIZE_TOOL_ENHANCEMENT_PLAN.md` (comprehensive design doc)
2. Execute: `sql/create_document_prompts.sql` (database setup)
3. Follow phases below in order

---

## Phase 1: Database & Infrastructure ✓

### Database Setup
- [ ] Review `sql/create_document_prompts.sql`
- [ ] Execute SQL script on development database
- [ ] Verify table created: `SELECT TOP 1 * FROM docketwatch.dbo.document_prompts`
- [ ] Test foreign key constraint with sample insert
- [ ] Verify all indexes created (6 indexes expected)

### Testing
- [ ] Insert test prompt record manually
- [ ] Query by doc_uid
- [ ] Query by user_name
- [ ] Query by session_id
- [ ] Delete test record

**Completion Criteria:** Database table and indexes exist, manual queries work

---

## Phase 2: Python Q&A Script ✓

### File: `/python/answer_from_json.py`

**Tasks:**
- [ ] Create new Python file
- [ ] Implement `load_document_json(doc_uid)` function
  - [ ] Connect to SQL Server via pyodbc
  - [ ] Query `documents` table for `summary_ai_extraction_json`
  - [ ] Parse JSON and return dict
  - [ ] Handle errors (doc not found, invalid JSON)

- [ ] Implement `answer_from_facts(extraction, question)` function
  - [ ] Build system prompt with FACT_GUARD rules
  - [ ] Call Gemini API with extraction JSON + user question
  - [ ] Parse response and extract answer
  - [ ] Track token usage
  - [ ] Return structured dict

- [ ] Implement `extract_citations(response_text, extraction)` function
  - [ ] Parse response for field references
  - [ ] Match field values to response content
  - [ ] Return list of cited field paths

- [ ] Implement `main()` CLI entry point
  - [ ] Parse command-line arguments: `--doc_uid`, `--prompt`
  - [ ] Call processing functions
  - [ ] Output JSON to stdout
  - [ ] Handle errors gracefully

### Testing
- [ ] Test with sample doc_uid and simple question
  ```bash
  python answer_from_json.py --doc_uid=TEST-UUID --prompt="What was the settlement amount?"
  ```
- [ ] Verify JSON output format
- [ ] Test with question not in facts (should say "not available")
- [ ] Test with malformed doc_uid (should return error JSON)
- [ ] Test citation extraction accuracy

**Completion Criteria:** Script runs successfully, returns valid JSON with answer and citations

---

## Phase 3: Backend CFML Endpoints ✓

### File 1: `/ajax/ask_document_question.cfm`

**Tasks:**
- [ ] Create new CFML file
- [ ] Add JSON header and error handling
- [ ] Parse POST parameters: `doc_uid`, `prompt_text`, `session_id`
- [ ] Load document from database
  ```cfm
  <cfquery name="getDoc" datasource="Reach">
      SELECT doc_uid, summary_ai_extraction_json
      FROM docketwatch.dbo.documents
      WHERE doc_uid = <cfqueryparam value="#form.doc_uid#" ...>
  </cfquery>
  ```
- [ ] Validate document exists
- [ ] Check user access permissions
- [ ] Implement rate limiting (50 prompts/hour)
  ```cfm
  <cfquery name="checkRate" datasource="Reach">
      SELECT COUNT(*) FROM document_prompts
      WHERE user_name = ... AND created_at > DATEADD(hour, -1, ...)
  </cfquery>
  ```
- [ ] Call Python script via `cfexecute`
  ```cfm
  <cfexecute name="python.exe"
             arguments="#[scriptPath, '--doc_uid', docUid, '--prompt', prompt]#"
             variable="pyOutput" ...>
  </cfexecute>
  ```
- [ ] Parse Python JSON response
- [ ] Insert prompt record into `document_prompts` table
- [ ] Calculate next `prompt_sequence` for session
- [ ] Return JSON response to frontend

**Testing:**
- [ ] Test with valid doc_uid and prompt (Postman/curl)
- [ ] Test with invalid doc_uid (should return 404)
- [ ] Test rate limiting (make 51 requests in 1 hour)
- [ ] Test access control (different user tries to access doc)
- [ ] Verify database insert occurred

### File 2: `/ajax/save_prompt_feedback.cfm`

**Tasks:**
- [ ] Create new CFML file
- [ ] Parse POST parameters: `prompt_id`, `rating`, `comment`
- [ ] Update prompt record with feedback
  ```cfm
  <cfquery datasource="Reach">
      UPDATE docketwatch.dbo.document_prompts
      SET feedback_rating = ...,
          feedback_comment = ...,
          feedback_submitted_at = SYSUTCDATETIME()
      WHERE id = ...
  </cfquery>
  ```
- [ ] Return success JSON

**Testing:**
- [ ] Submit feedback for test prompt
- [ ] Verify database update
- [ ] Test with invalid prompt_id

### File 3: `/ajax/load_conversation_history.cfm`

**Tasks:**
- [ ] Create new CFML file
- [ ] Parse GET parameter: `doc_uid`
- [ ] Query all prompts for document
  ```cfm
  <cfquery name="getHistory" datasource="Reach">
      SELECT id, prompt_text, prompt_response, created_at,
             cited_fields, feedback_rating, prompt_sequence
      FROM docketwatch.dbo.document_prompts
      WHERE fk_doc_uid = ...
      ORDER BY created_at, prompt_sequence
  </cfquery>
  ```
- [ ] Return JSON array of prompts

**Testing:**
- [ ] Load history for doc with multiple prompts
- [ ] Verify correct order
- [ ] Test with doc_uid that has no prompts

**Completion Criteria:** All endpoints work correctly, database logging verified

---

## Phase 4: Frontend - Upload Page Redesign ✓

### File: `/tools/summarize/index.cfm`

**Tasks:**
- [ ] Backup existing `index.cfm`
- [ ] Redesign layout to centered single-column (max-width: 600px)
- [ ] Enlarge upload dropzone (fa-5x icon)
- [ ] Update CSS for cleaner look
- [ ] Remove right-side results panel
- [ ] Create processing modal (Bootstrap 5)
  ```html
  <div class="modal fade" id="processingModal" data-bs-backdrop="static">
      <!-- Progress bars for 4 stages -->
  </div>
  ```
- [ ] Update JavaScript to show modal on button click
- [ ] Implement progress polling (optional: can be fake progress for now)
- [ ] On completion, redirect to results page:
  ```javascript
  window.location.href = `/tools/summarize/view.cfm?doc_uid=${docUid}`;
  ```

**Testing:**
- [ ] Upload PDF, verify modal appears
- [ ] Verify progress bars animate
- [ ] Verify redirect to view.cfm with correct doc_uid parameter
- [ ] Test on mobile (responsive design)

**Completion Criteria:** Upload flow works, modal displays, redirects correctly

---

## Phase 5: Frontend - Results & Q&A Page ✓

### File: `/tools/summarize/view.cfm` (NEW)

**Tasks:**

#### Page Structure
- [ ] Create new file `view.cfm`
- [ ] Add authentication check
- [ ] Parse URL parameter `doc_uid`
- [ ] Load document from database
  ```cfm
  <cfquery name="getDoc" datasource="Reach">
      SELECT doc_uid, pdf_title, ocr_text, summary_ai_html,
             summary_ai_extraction_json
      FROM docketwatch.dbo.documents
      WHERE doc_uid = <cfqueryparam value="#url.doc_uid#" ...>
  </cfquery>
  ```
- [ ] Verify user access

#### Summary Section
- [ ] Display summary with more vertical space
- [ ] Use existing summary rendering logic from index.cfm
- [ ] Add "Download as PDF" button (optional)

#### Tabbed Interface
- [ ] Create Bootstrap tabs: Summary | JSON | OCR
- [ ] Tab 1: Show formatted summary HTML
- [ ] Tab 2: Show prettified JSON with syntax highlighting
- [ ] Tab 3: Show OCR text in monospace font

#### Q&A Section
- [ ] Add conversation history container (scrollable div)
- [ ] Add prompt input field + Ask button
- [ ] Implement JavaScript for Ask button:
  ```javascript
  $('#askButton').click(async function() {
      const prompt = $('#promptInput').val();
      const response = await fetch('/ajax/ask_document_question.cfm', {
          method: 'POST',
          body: JSON.stringify({
              doc_uid: docUid,
              prompt_text: prompt,
              session_id: sessionId
          })
      });
      const data = await response.json();
      appendMessage('user', prompt);
      appendMessage('ai', data.response_text, data.cited_fields, data.prompt_id);
  });
  ```
- [ ] Implement `appendMessage()` function to add conversation bubbles
- [ ] Style user messages (right-aligned, blue)
- [ ] Style AI messages (left-aligned, gray, with citations)
- [ ] Add timestamp to each message
- [ ] Add feedback buttons (thumbs up/down) to AI messages
- [ ] Implement feedback submission:
  ```javascript
  function submitFeedback(promptId, rating) {
      fetch('/ajax/save_prompt_feedback.cfm', {
          method: 'POST',
          body: JSON.stringify({ prompt_id: promptId, rating: rating })
      });
  }
  ```

#### Page Load
- [ ] On page load, call `/ajax/load_conversation_history.cfm`
- [ ] Display previous prompts if any exist
- [ ] Generate new session_id if first visit

**Testing:**
- [ ] Load view.cfm with valid doc_uid
- [ ] Verify summary displays correctly
- [ ] Verify tabs switch properly
- [ ] Ask a question, verify AI response appears
- [ ] Ask multiple questions, verify conversation history grows
- [ ] Submit feedback, verify it saves
- [ ] Reload page, verify history persists

**Completion Criteria:** Full Q&A workflow functional, conversation history works

---

## Phase 6: Integration & Testing ✓

### End-to-End Tests
- [ ] **Test 1: Happy Path**
  - Upload PDF → Process → Redirect → View results → Ask question → Get answer
  - Verify all data logged to database
  - Verify feedback submission

- [ ] **Test 2: Multiple Questions**
  - Ask 5 questions in a row
  - Verify conversation order correct
  - Verify prompt_sequence increments

- [ ] **Test 3: Edge Cases**
  - Question outside scope of facts → Should say "not available"
  - Very long prompt (500+ chars) → Should handle or reject
  - Rapid clicks on Ask button → Should queue or disable button

- [ ] **Test 4: Different Document Types**
  - Criminal complaint
  - Civil motion
  - Court order
  - Settlement agreement

- [ ] **Test 5: Error Scenarios**
  - Invalid doc_uid → Show 404 page
  - Python script timeout → Show friendly error
  - Database connection failure → Show maintenance message

### Performance Tests
- [ ] Upload 10 documents and measure average processing time
- [ ] Submit 20 prompts and measure response times (should be < 3 sec)
- [ ] Check database query performance (review execution plans)
- [ ] Monitor Gemini API rate limits

### Security Tests
- [ ] Test SQL injection in prompt_text
- [ ] Test XSS in displayed responses
- [ ] Test access control (user A can't see user B's doc)
- [ ] Test rate limiting enforcement

**Completion Criteria:** All tests pass, no critical bugs

---

## Phase 7: Polish & Deployment ✓

### UI Polish
- [ ] Add keyboard shortcut (Enter to submit prompt)
- [ ] Add loading spinner while waiting for AI response
- [ ] Disable Ask button while processing
- [ ] Add "Copy" button to code blocks
- [ ] Add "Clear conversation" button
- [ ] Improve mobile responsiveness

### Documentation
- [ ] Write user guide (how to use Q&A feature)
- [ ] Update CLAUDE.md with new features
- [ ] Document API endpoints for future developers
- [ ] Create troubleshooting guide

### Deployment
- [ ] Review all code changes (code review)
- [ ] Run full test suite
- [ ] Deploy to staging environment
- [ ] UAT with TMZ team (gather feedback)
- [ ] Fix any bugs found in UAT
- [ ] Deploy to production
- [ ] Monitor logs for errors

**Completion Criteria:** Deployed to production, no critical issues

---

## Phase 8: Analytics & Monitoring ✓

### Dashboards
- [ ] Create usage dashboard:
  - Total prompts per day
  - Most active users
  - Average rating by user
  - Most common questions
- [ ] Create cost dashboard:
  - Gemini API token usage
  - Estimated monthly cost
  - Cost per prompt

### Monitoring
- [ ] Set up alerts for:
  - Error rate > 5%
  - Response time > 5 seconds (P95)
  - Rate limit violations
- [ ] Monitor Gemini API quota usage
- [ ] Track feedback ratings over time

### Analysis
- [ ] Analyze prompt patterns (what are users asking?)
- [ ] Identify common failure cases
- [ ] Gather feature requests from feedback comments

**Completion Criteria:** Dashboards live, alerts configured, first analysis report

---

## Success Criteria

### Must Have (MVP)
- ✅ Users can upload PDFs and see summary
- ✅ Users can ask questions about document
- ✅ AI answers using only extracted facts
- ✅ Conversation history persists
- ✅ Feedback mechanism works

### Nice to Have (V1.1)
- 🔲 Export conversation as PDF
- 🔲 Suggested questions
- 🔲 Voice input
- 🔲 Multi-document comparison

### Metrics Targets
- **Adoption:** >30% of documents receive follow-up questions
- **Engagement:** Average 3+ prompts per document
- **Accuracy:** >80% positive feedback
- **Performance:** <3 sec response time (P95)
- **Reliability:** <1% error rate

---

## Risk Management

| Risk | Impact | Mitigation |
|------|--------|------------|
| Gemini API rate limits | High | Implement queue, fallback to cached responses |
| Python script timeouts | Medium | Increase timeout, optimize extraction |
| Database performance | Medium | Add indexes, cache frequent queries |
| User dissatisfaction | High | Thorough UAT, gather feedback early |
| Cost overruns | Medium | Monitor API usage, set quotas |

---

## Contacts

- **Product Owner:** [Name]
- **Developer:** [Name]
- **DBA:** [Name]
- **QA Lead:** [Name]

---

## Notes

- Keep this checklist updated as work progresses
- Mark items complete only after testing
- Document any deviations from plan
- Escalate blockers immediately

---

**Last Updated:** 2025-01-28
