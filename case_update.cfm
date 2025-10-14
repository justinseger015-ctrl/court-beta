<cfparam name="case_mode" default="update">

<cfquery name="getCase" datasource="reach">
SELECT 
    id, 
    case_number, 
    case_name,
    status, 
    fk_court, 
    case_type, 
    case_url, 
    fk_tool, 
    fk_priority
FROM docketwatch.dbo.cases
WHERE id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
</cfquery>
<!--- PRIORITY --->
<cfquery name="getPriorities" datasource="reach">
SELECT id, name as display
FROM docketwatch.dbo.case_priority
WHERE id <> 0
ORDER BY id
</cfquery>

<!--- TOOL --->
<cfquery name="getTools" datasource="reach">
SELECT id, tool_name as display
FROM docketwatch.dbo.tools
WHERE id NOT IN (9,10,11,1)
ORDER BY tool_name
</cfquery>

<!--- STATUS --->
<cfquery name="getStatus" datasource="reach">
SELECT DISTINCT status as id, status as display
FROM docketwatch.dbo.cases
ORDER BY status
</cfquery>

<cfquery name="getStates" datasource="reach">
SELECT state_code, state_name FROM docketwatch.dbo.states ORDER BY state_name
</cfquery>

<cfquery name="getCounties" datasource="reach">
SELECT id, name, state_code FROM docketwatch.dbo.counties
ORDER BY name
</cfquery>

<cfquery name="getCourts" datasource="reach">
SELECT o.court_code as id, o.court_name + ' (' + u.name + ')' as display, u.id as county_id, u.state_code
FROM docketwatch.dbo.courts o
INNER JOIN docketwatch.dbo.counties u ON u.id = o.fk_county
ORDER BY o.court_name
</cfquery>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title><cfif case_mode EQ "new">New Case Form<cfelse><cfoutput>Update Case - #getCase.case_number#</cfoutput></cfif></title>
  <cfinclude template="head.cfm">
</head>
<body>

<cfinclude template="navbar.cfm">

<div class="container-fluid mt-4">
  <!-- Minimal header section matching search form style -->
  <div class="container">
    <div class="card shadow-sm mb-4 filter-card">
      <div class="card-header">
        <h6 class="mb-0 d-flex align-items-center">
          <cfif case_mode EQ "new">
            <i class="fas fa-plus me-2"></i>New Case Form
          <cfelse>
            <i class="fas fa-edit me-2"></i>Update Case - <cfoutput>#getCase.case_number#</cfoutput>
          </cfif>
          <div class="ms-auto d-flex gap-2">
            <cfoutput>
            <a href="<cfif case_mode EQ 'new'>index.cfm<cfelse>case_details.cfm?id=#getCase.id#</cfif>" 
               class="btn btn-outline-secondary btn-sm"
               aria-label="Cancel and return">
              <i class="fas fa-times me-1" aria-hidden="true"></i>
              Cancel
            </a>
            </cfoutput>
          </div>
        </h6>
      </div>
    </div>
  </div>

  <div class="container">
    <div class="card shadow-sm mb-4 filter-card">
      <div class="card-header">
        <h6 class="mb-0">
          <i class="fas fa-file-alt me-2"></i>
          <cfif case_mode EQ "new">New Case Form<cfelse>Case Update Form</cfif>
        </h6>
      </div>
      <div class="card-body">
        <form method="post" action="save_case_update.cfm" id="updateForm">
          <cfoutput>
          <input type="hidden" name="id" value="#getCase.id#">
          <input type="hidden" name="case_mode" value="#case_mode#">
          </cfoutput>

          <!-- Basic Case Information -->
          <div class="mb-4">
            <h6 class="text-muted mb-3">
              <i class="fas fa-file-alt me-2" aria-hidden="true"></i>
              Basic Case Information
            </h6>
            <div class="row">
              <div class="col-md-6">
                <div class="mb-3">
                  <label for="case_number" class="form-label">
                    <i class="fas fa-hashtag me-1" aria-hidden="true"></i>
                    Case Number
                  </label>
                  <cfoutput>
                  <input type="text" 
                         class="form-control" 
                         id="case_number" 
                         name="case_number" 
                         value="#getCase.case_number#"
                         >
                  </cfoutput>
                </div>
              </div>
              <div class="col-md-6">
                <div class="mb-3">
                  <label for="case_name" class="form-label">
                    <i class="fas fa-signature me-1" aria-hidden="true"></i>
                    Case Name
                  </label>
                  <cfoutput>
                  <input type="text" 
                         class="form-control" 
                         id="case_name" 
                         name="case_name" 
                         value="#getCase.case_name#"
                         >
                  </cfoutput>
                </div>
              </div>
            </div>
            
            <div class="mb-3">
              <label for="case_url" class="form-label">
                <i class="fas fa-link me-1" aria-hidden="true"></i>
                Case URL
              </label>
              <cfoutput>
              <input type="url" 
                     class="form-control" 
                     id="case_url" 
                     name="case_url" 
                     value="#getCase.case_url#"
                     placeholder="https://...">
              </cfoutput>
            </div>
            
            <cfif case_mode NEQ "new">
            <div class="mb-0">
              <label for="case_type" class="form-label">
                <i class="fas fa-folder-open me-1" aria-hidden="true"></i>
                Case Type
              </label>
              <cfoutput>
              <input type="text" 
                     class="form-control" 
                     id="case_type" 
                     name="case_type" 
                     value="#getCase.case_type#">
              </cfoutput>
            </div>
            </cfif>
          </div>
          <!-- Case Status & Settings -->
          <div class="mb-4">
            <h6 class="text-muted mb-3">
              <i class="fas fa-cogs me-2" aria-hidden="true"></i>
              Case Status & Settings
            </h6>
            <div class="row">
              <div class="col-md-4">
                <div class="mb-3">
                  <label for="status" class="form-label">
                    <i class="fas fa-flag me-1" aria-hidden="true"></i>
                    Status
                  </label>
                  <select class="form-select" id="status" name="status" required>
                    <cfoutput query="getStatus">
                      <option value="#id#" <cfif getCase.status EQ id>selected</cfif>>#display#</option>
                    </cfoutput>
                  </select>
                </div>
              </div>
              <div class="col-md-4">
                <div class="mb-3">
                  <label for="fk_priority" class="form-label">
                    <i class="fas fa-exclamation-triangle me-1" aria-hidden="true"></i>
                    Priority
                  </label>
                  <select class="form-select" id="fk_priority" name="fk_priority">
                    <cfoutput query="getPriorities">
                      <option value="#id#" <cfif getCase.fk_priority EQ id>selected</cfif>>#display#</option>
                    </cfoutput>
                  </select>
                </div>
              </div>
              <div class="col-md-4">
                <div class="mb-0">
                  <label for="fk_tool" class="form-label">
                    <i class="fas fa-tools me-1" aria-hidden="true"></i>
                    Tool
                  </label>
                  <select class="form-select" id="fk_tool" name="fk_tool">
                    <cfoutput query="getTools">
                      <option value="#id#" <cfif getCase.fk_tool EQ id>selected</cfif>>#display#</option>
                    </cfoutput>
                  </select>
                </div>
              </div>
            </div>
          </div>

        <cfif case_mode NEQ "new">
          <!-- Court Location -->
          <div class="mb-4">
            <h6 class="text-muted mb-3">
              <i class="fas fa-map-marker-alt me-2" aria-hidden="true"></i>
              Court Location
            </h6>
            <div class="row">
              <div class="col-md-4">
                <div class="mb-3">
                  <label for="stateSelect" class="form-label">
                    <i class="fas fa-flag-usa me-1" aria-hidden="true"></i>
                    State
                  </label>
                  <select id="stateSelect" class="form-select">
                    <option value="">Select State</option>
                    <cfoutput query="getStates">
                      <option value="#state_code#"
                        <cfif getCase.fk_court neq "" and getCase.fk_court eq getCourts.id and getCourts.state_code eq state_code>
                          selected
                        </cfif>
                      >#state_name#</option>
                    </cfoutput>
                  </select>
                </div>
              </div>
              <div class="col-md-4">
                <div class="mb-3">
                  <label for="countySelect" class="form-label">
                    <i class="fas fa-city me-1" aria-hidden="true"></i>
                    County
                  </label>
                  <select id="countySelect" class="form-select">
                    <option value="">Select County</option>
                  </select>
                </div>
              </div>
              <div class="col-md-4">
                <div class="mb-0">
                  <label for="fk_court" class="form-label">
                    <i class="fas fa-university me-1" aria-hidden="true"></i>
                    Court
                  </label>
                  <select id="fk_court" name="fk_court" class="form-select">
                    <option value="">Select Court</option>
                  </select>
                </div>
              </div>
            </div>
          </div>
        </cfif>


        <!-- Update Options -->
        <div class="mb-4">
          <h6 class="text-muted mb-3">
            <i class="fas fa-cog me-2" aria-hidden="true"></i>
            Update Options
          </h6>
          <div class="form-check">
            <input class="form-check-input" 
                   type="checkbox" 
                   id="update_external" 
                   name="update_external"
                   <cfif case_mode EQ "new">checked</cfif>>
            <label class="form-check-label" for="update_external">
              <i class="fas fa-sync me-1" aria-hidden="true"></i>
              Update externally
            </label>
          </div>
        </div>

          <!-- Action Buttons -->
          <div class="border-top pt-3 mt-4">
            <div class="d-flex justify-content-end gap-2">
              <cfoutput>
                <a href="<cfif case_mode EQ 'new'>index.cfm<cfelse>case_details.cfm?id=#getCase.id#</cfif>" class="btn btn-outline-secondary">
                  <i class="fas fa-times me-1" aria-hidden="true"></i>
                  Cancel
                </a>
              </cfoutput>
              <button type="submit" class="btn btn-primary">
                <i class="fas fa-<cfif case_mode EQ 'new'>plus<cfelse>save</cfif> me-1" aria-hidden="true"></i>
                <cfif case_mode EQ "new">Add Case<cfelse>Update Case</cfif>
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</div>


 
<!-- Loading Modal -->
<div class="modal fade" id="updateSpinnerModal" tabindex="-1" role="dialog" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered" role="document">
    <div class="modal-content">
      <div class="modal-body text-center p-5">
        <div class="spinner-border text-primary mb-3" role="status" style="width: 3rem; height: 3rem;">
          <span class="visually-hidden">Loading...</span>
        </div>
        <h5 class="mb-2">
          <i class="fas fa-sync-alt me-2" aria-hidden="true"></i>
          Synchronizing Case Data
        </h5>
        <p class="text-muted mb-0">Please wait while we update the case information...</p>
      </div>
    </div>
  </div>
</div>

<script>
$('#updateSpinnerModal').modal('show');
$.ajax({
  url: 'run_pacer_update.cfm',
  method: 'POST',
  data: { case_id: yourCaseId },
  success: function(response) {
    $('#updateSpinnerModal').modal('hide');
    // maybe show success toast
  },
  error: function() {
    $('#updateSpinnerModal').modal('hide');
    alert("Something went wrong. Please try again.");
  }
});
</script>
<script>
  // County array: [{id, name, state_code}]
  var counties = [
    <cfoutput query="getCounties">
      {id: '#id#', name: '#JSStringFormat(name)#', state_code: '#state_code#'}<cfif getCounties.currentRow LT getCounties.recordCount>,</cfif>
    </cfoutput>
  ];
  // Court array: [{id, display, county_id}]
  var courts = [
    <cfoutput query="getCourts">
      {id: '#id#', display: '#JSStringFormat(display)#', county_id: '#county_id#'}<cfif getCourts.currentRow LT getCourts.recordCount>,</cfif>
    </cfoutput>
  ];
</script>

<script>
  // Prefill for edit mode
  var initialCourtId = "<cfoutput>#getCase.fk_court#</cfoutput>";

  function filterCounties(stateCode) {
    $('#countySelect').empty().append('<option value="">Select County</option>');
    counties.filter(c => c.state_code === stateCode).forEach(function(c) {
      $('#countySelect').append(`<option value="${c.id}">${c.name}</option>`);
    });
    $('#countySelect').trigger('change');
  }

  function filterCourts(countyId) {
    $('#fk_court').empty().append('<option value="">Select Court</option>');
    courts.filter(c => c.county_id == countyId).forEach(function(c) {
      $('#fk_court').append(`<option value="${c.id}">${c.display}</option>`);
    });
    $('#fk_court').trigger('change');
  }

  // On state change, update counties
  $('#stateSelect').on('change', function() {
    filterCounties(this.value);
    $('#fk_court').empty().append('<option value="">Select Court</option>');
  });

  // On county change, update courts
  $('#countySelect').on('change', function() {
    filterCourts(this.value);
  });

  // Prefill if editing
  $(document).ready(function() {
    if (initialCourtId) {
      // Find the selected court's county/state
      var selectedCourt = courts.find(c => c.id == initialCourtId);
      if (selectedCourt) {
        var selectedCounty = counties.find(c => c.id == selectedCourt.county_id);
        if (selectedCounty) {
          $('#stateSelect').val(selectedCounty.state_code);
          filterCounties(selectedCounty.state_code);
          $('#countySelect').val(selectedCourt.county_id);
          filterCourts(selectedCourt.county_id);
          $('#fk_court').val(initialCourtId);
        }
      }
    }
  });
</script>
<cfinclude template="footer_script.cfm">
<script>
document.querySelector("form").addEventListener("submit", function(e) {
  const updateExternal = document.getElementById("update_external").checked;
  if (updateExternal) {
    $('#updateSpinnerModal').modal('show');
  }
});
</script>
</body>
</html>
