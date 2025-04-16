// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require_tree .

// Global API object for authentication
window.API = {
  auth: {
    logout: async function () {
      try {
        const response = await fetch("/api/v1/auth/logout", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('[name="csrf-token"]')
              ?.content,
          },
        });
        const data = await response.json();
        return data;
      } catch (error) {
        return { error: "Failed to log out" };
      }
    },
  },
};

// Simple document-ready function
document.addEventListener("DOMContentLoaded", function () {
  const logoutLinks = document.querySelectorAll("[data-action='logout']");

  logoutLinks.forEach(link => {
    link.addEventListener("click", async function (e) {
      e.preventDefault();

      try {
        await window.API.auth.logout();
        window.location.href = "/";
      } catch (error) {
        console.error("Logout error:", error);
      }
    });
  });
});
