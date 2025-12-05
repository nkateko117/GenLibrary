document.addEventListener("DOMContentLoaded", () => {

    const form = document.getElementById("bookFilterForm");

    form.addEventListener("submit", async (e) => {
        e.preventDefault();

        const formData = new FormData(form);

        const response = await fetch("/Books/Filter", {
            method: "POST",
            body: formData
        });

        const html = await response.text();

        document.getElementById("bookTableContainer").innerHTML = html;
    });
});
