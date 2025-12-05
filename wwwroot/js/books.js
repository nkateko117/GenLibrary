document.addEventListener("DOMContentLoaded", () => {

    // Initialize DataTable
    $('#booksTable').DataTable({
        pageLength: 10,
        ordering: true,
        responsive: true
    });
});
