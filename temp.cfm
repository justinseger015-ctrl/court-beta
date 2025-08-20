    <cfif dockets.recordcount GT 0>
                <cfoutput query="dockets">
                    <cfif len(dockets.pdf_path) OR len(dockets.summary_ai_html)>
                        <div class="modal fade" id="documentModal#dockets.id#" tabindex="-1" aria-labelledby="documentModalLabel#dockets.id#" aria-hidden="true">
                            <div class="modal-dialog modal-lg">
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <h5 class="modal-title" id="documentModalLabel#dockets.id#">
                                            #dockets.pdf_title#
                                        </h5>
                                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                                    </div>
                                    <!-- Document Modals (Corrected, safe ColdFusion pattern) -->
                                        <div class="row">
                                            <!--- Left third: PDF icon --->
                                            <div class="col-md-4 text-center">
                                                <cfif len(dockets.pdf_path)>
                                                    <a href="#dockets.pdf_path#" target="_blank" class="btn btn-success btn-lg mb-3">
                                                        <i class="fas fa-file-pdf fa-3x"></i>
                                                        <br><small>View PDF</small>
                                                    </a>
                                                <cfelse>
                                                    <div class="text-muted mb-3">
                                                        <i class="fas fa-file-text fa-3x"></i>
                                                        <br><small>Summary Only</small>
                                                    </div>
                                                </cfif>
                                                <!--- Document Specifications --->
                                                <div class="document-specs text-start">
                                                    <div class="card bg-light border-0">
                                                        <div class="card-body p-3">
                                                            <h6 class="card-title mb-2 text-primary">
                                                                <i class="fas fa-info-circle me-1"></i>Document Details
                                                            </h6>
                                                            <!--- Document Name --->
                                                            <div class="mb-2">
                                                                <strong class="text-muted small">Document:</strong>
                                                                <div class="small text-dark">
                                                                    <cfif len(dockets.pdf_title)>
                                                                        #dockets.pdf_title#
                                                                    <cfelse>
                                                                        Docket Entry ###dockets.event_no#
                                                                    </cfif>
                                                                </div>
                                                            </div>
                                                            <!--- Filing Date --->
                                                            <div class="mb-2">
                                                                <strong class="text-muted small">Filed:</strong>
                                                                <div class="small text-dark">
                                                                    #dateFormat(dockets.event_date, "mmm dd, yyyy")#
                                                                </div>
                                                            </div>
                                                            <!--- Docket Number --->
                                                            <div class="mb-2">
                                                                <strong class="text-muted small">Docket ###:</strong>
                                                                <div class="small text-dark">#dockets.event_no#</div>
                                                            </div>
                                                            <!--- Document Type --->
                                                            <cfif len(dockets.pdf_path)>
                                                                <div class="mb-2">
                                                                    <strong class="text-muted small">Type:</strong>
                                                                    <div class="small text-dark">
                                                                        <i class="fas fa-file-pdf text-danger me-1"></i>PDF Document
                                                                    </div>
                                                                </div>
                                                            </cfif>
                                                            <!--- Status/Result if available --->
                                                            <cfif len(dockets.event_result)>
                                                                <div class="mb-0">
                                                                    <strong class="text-muted small">Status:</strong>
                                                                    <div class="small text-dark">#dockets.event_result#</div>
                                                                </div>
                                                            </cfif>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                            <!--- Right two-thirds: Summary --->
                                            <div class="col-md-8">
                                                <cfif len(dockets.summary_ai_html)>
                                                    <h6>Summary:</h6>
                                                    <div class="summary-content">
                                                        #dockets.summary_ai_html#
                                                    </div>
                                                <cfelse>
                                                    <p class="text-muted">No summary available for this document.</p>
                                                </cfif>
                                            </div>
                                        </div>
                                        <!--- Only show HR and attachments section if there are attachments for this docket --->
                                        <cfset hasAttachments = false>
                                        <cfif attachments.recordCount GT 0>
                                            <cfloop query="attachments">
                                                <cfif attachments.fk_case_event EQ dockets.id>
                                                    <cfset hasAttachments = true>
                                                    <cfbreak>
                                                </cfif>
                                            </cfloop>
                                        </cfif>
                                        <cfif hasAttachments>
                                            <!--- Horizontal rule before attachments --->
                                            <hr>
                                            <!--- Attachments section --->
                                            <div class="attachments-section">
                                                <h6>Attachments:</h6>
                                                <div class="row">
                                                    <cfloop query="attachments">
                                                        <cfif attachments.fk_case_event EQ dockets.id>
                                                            <div class="col-md-3 mb-2">
                                                                <cfif len(attachments.pdf_path)>
                                                                    <a href="#attachments.pdf_path#" target="_blank" 
                                                                       class="btn btn-outline-primary btn-sm d-block"
                                                                       title="#attachments.pdf_title#">
                                                                        <i class="fas fa-paperclip"></i>
                                                                        <br><small>#left(attachments.pdf_title, 20)#<cfif len(attachments.pdf_title) GT 20>...</cfif></small>
                                                                    </a>
                                                                <cfelse>
                                                                    <span class="btn btn-outline-secondary btn-sm d-block disabled"
                                                                          title="#attachments.pdf_title#">
                                                                        <i class="fas fa-paperclip"></i>
                                                                        <br><small>#left(attachments.pdf_title, 20)#<cfif len(attachments.pdf_title) GT 20>...</cfif></small>
                                                                    </span>
                                                                </cfif>
                                                            </div>
                                                        </cfif>
                                                    </cfloop>
                                                </div>
                                            </div>
                                        </cfif>
                                    </div>
                                    <div class="modal-footer">
                                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </cfif>
                </cfoutput>
            </cfif>