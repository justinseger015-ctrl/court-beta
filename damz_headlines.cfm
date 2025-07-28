<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>DocketWatch - Optimized Headlines</title>
  <cfinclude template="head.cfm">
  <style>
    .headline-original { color: #666; font-size: 0.9em; }
    .headline-optimized { color: #000; font-weight: bold; }
    .edit-btn { font-size: 0.8em; }
  </style>
</head>
<body>
<cfinclude template="navbar.cfm">

<div class="container mt-4">
  <div class="d-flex justify-content-between align-items-center mb-3">
    <h2 class="mb-0">Optimized DAMZ Headlines</h2>
  </div>
  <table id="headlinesTable" class="table table-striped table-bordered w-100">
    <thead class="table-dark">
      <tr>
        <th>Type</th>
        <th>Original → Optimized</th>
        <th>Actions</th>
        <th class="d-none">Asset ID</th>
      </tr>
    </thead>
  </table>
</div>

<!-- Modal -->
<div class="modal fade" id="editModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-lg modal-dialog-scrollable">
    <div class="modal-content">
      <form id="editForm">
        <div class="modal-header">
          <h5 class="modal-title">Edit Headline</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <input type="hidden" name="fk_asset" id="fk_asset" />
          <div class="mb-3">
            <label class="form-label">Headline Type</label>
            <select name="headline_type_final" id="headline_type_final" class="form-select">
              <cfquery name="types" datasource="reach">
                SELECT type_label FROM docketwatch.dbo.headline_types WHERE is_active = 1 ORDER BY type_label
              </cfquery>
              <cfoutput query="types">
                <option value="#type_label#">#type_label#</option>
              </cfoutput>
            </select>
          </div>
          <div class="mb-3">
            <label class="form-label">Final Headline</label>
            <textarea name="headline_final" id="headline_final" class="form-control" rows="3"></textarea>
          </div>
          <div class="form-check mb-2">
            <input type="checkbox" class="form-check-input" name="approved" id="approved" value="1" />
            <label class="form-check-label" for="approved">Mark as Approved</label>
          </div>
        </div>
        <div class="modal-footer">
          <button type="submit" class="btn btn-primary">Save Changes</button>
        </div>
      </form>
    </div>
  </div>
</div>

<cfinclude template="footer_script.cfm">

<script>
let table;

$(document).ready(function () {
  table = $('#headlinesTable').DataTable({
    ajax: {
      url: "get_headlines_ajax.cfm",
      dataSrc: ""
    },
    columns: [
      { data: "headline_type_final" },
      {
        data: null,
        render: function (data, type, row) {
          const escapeHtml = str => String(str || '')
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");

          return (
            '<div class="headline-original">' + escapeHtml(data.headline) + '</div>' +
            '<div class="headline-optimized">' + escapeHtml(data.headline_final) + '</div>'
          );
        }
      },
      {
        data: null,
        render: function (data) {
          return '<button class="btn btn-sm btn-secondary edit-btn" onclick="editRow(\'' + data.fk_asset + '\')">Edit</button>';
        }
      },
      { data: "fk_asset", visible: false }
    ],
    order: [[3, 'desc']],
    pageLength: 50
  });
});

function editRow(fk_asset) {
  const rowData = table.rows().data().toArray().find(r => r.fk_asset == fk_asset);
  if (!rowData) return;

  $('#fk_asset').val(rowData.fk_asset);
  $('#headline_final').val(rowData.headline_final);
  $('#headline_type_final').val(rowData.headline_type_final);
  $('#approved').prop('checked', rowData.approved == 1);

  new bootstrap.Modal('#editModal').show();
}

$('#editForm').on('submit', function (e) {
  e.preventDefault();
  $.post('save_headline_update.cfm', $(this).serialize(), function (res) {
    $('#editModal').modal('hide');
    table.ajax.reload(null, false);
  });
});

// Optional: catch JS errors globally for debugging
window.addEventListener("error", function (e) {
  console.error("Script error:", e.message, e.filename, e.lineno);
});
</script>

</body>
</html>
