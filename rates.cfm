<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>Murder Rate Buttons</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    :root { --gap: 14px; --btn-pad: 16px 18px; --radius: 10px; }
    body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; margin: 24px; }
    h1 { font-size: 18px; margin: 0 0 12px 0; }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
      gap: var(--gap);
    }
    button.rate {
      display: inline-block;
      width: 100%;
      padding: var(--btn-pad);
      border-radius: var(--radius);
      border: 1px solid #ddd;
      background: #fafafa;
      font-size: 18px;
      cursor: pointer;
      transition: background 0.15s, border-color 0.15s;
    }
    button.rate:hover { background: #f0f0f0; border-color: #ccc; }
    .item { display: flex; flex-direction: column; gap: 8px; }
    .details {
      display: none;
      padding: 10px 12px;
      border-left: 3px solid #ddd;
      background: #fcfcfc;
      border-radius: 6px;
      font-size: 14px;
      color: #333;
    }
    .details strong { font-weight: 600; }
    .show .details { display: block; }
    .legend { font-size: 12px; color: #666; margin-bottom: 16px; }
  </style>
</head>
<body>
  <h1>Murder rate (per 100K)</h1>
  <div class="legend">Data provided by requestor. Buttons show rate only. Click to toggle details.</div>

  <div class="grid" id="grid">
    <!-- Items are injected below via JS for clarity -->
  </div>

  <script>
    // Data exactly as provided by the user.
    const data = [
      { rate: 78.7, city: "Jackon, Missouri", party: "REPUBLICAN" },
      { rate: 58.8, city: "Birmingham, AL", party: "REPUBLICAN" },
      { rate: 54.1, city: "St. Louis, Missouri", party: "REPUBLICAN" },
      { rate: 40.6, city: "Memphis, Tennessee", party: "REPUBLICAN" },
      { rate: 30.0, city: "Cleveland, Ohio", party: "REPUBLICAN" },
      { rate: 29.7, city: "Dayton, Ohio", party: "REPUBLICAN" },
      { rate: 27.6, city: "Kansas City, Missouri", party: "REPUBLICAN" },
      { rate: 26.8, city: "Shreveport, Louisiana", party: "REPUBLICAN" },
      { rate: 24.2, city: "Richmond, Virginia", party: "REPUBLICAN" },
      { rate: 17.5, city: "Chicago, Illinois", party: "DEMOCRATIC" },
      { rate: 10.6, city: "Portland, Oregon", party: "DEMOCRATIC" }
    ];

    // Build the grid.
    const grid = document.getElementById("grid");
    data.forEach((row, idx) => {
      const item = document.createElement("div");
      item.className = "item";
      item.innerHTML = `
        <button class="rate" aria-expanded="false" aria-controls="d-${idx}" data-index="${idx}">
          ${row.rate}
        </button>
        <div class="details" id="d-${idx}">
          <div><strong>City:</strong> ${row.city}</div>
          <div><strong>Governor party:</strong> ${row.party}</div>
        </div>
      `;
      grid.appendChild(item);
    });

    // Toggle handler.
    grid.addEventListener("click", (e) => {
      const btn = e.target.closest("button.rate");
      if (!btn) return;
      const item = btn.parentElement;
      const expanded = btn.getAttribute("aria-expanded") === "true";
      btn.setAttribute("aria-expanded", String(!expanded));
      item.classList.toggle("show", !expanded);
    });
  </script>
</body>
</html>
