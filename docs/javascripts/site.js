(function () {
  if (window.mkdocs_page_input_path && window.mkdocs_page_input_path.indexOf("migration/") === 0) {
    document.body.classList.add("migration-page");
    document.querySelectorAll(".rst-content table").forEach(function (table) {
      if (table.rows[0]) {
        table.classList.add("migration-table-" + table.rows[0].cells.length);
      }
    });
  }
})();
