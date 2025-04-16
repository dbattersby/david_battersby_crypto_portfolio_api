import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "form",
    "email",
    "password",
    "name",
    "passwordConfirmation",
    "error",
  ];

  async login(event) {
    event.preventDefault();

    const email = this.emailTarget.value;
    const password = this.passwordTarget.value;

    try {
      const response = await window.API.auth.login(email, password);

      if (response.error) {
        this.showError(response.error);
        return;
      }

      // Success - redirect to portfolio
      window.location.href = "/portfolio";
    } catch (error) {
      this.showError("An error occurred during sign in. Please try again.");
      console.error("Sign in error:", error);
    }
  }

  async signup(event) {
    event.preventDefault();

    const userData = {
      name: this.nameTarget.value,
      email: this.emailTarget.value,
      password: this.passwordTarget.value,
      password_confirmation: this.passwordConfirmationTarget.value,
    };

    try {
      const response = await window.API.auth.signup(userData);

      if (response.errors) {
        this.showError(response.errors.join(", "));
        return;
      }

      // Success - redirect to portfolio
      window.location.href = "/portfolio";
    } catch (error) {
      this.showError("An error occurred during sign up. Please try again.");
      console.error("Sign up error:", error);
    }
  }

  async logout(event) {
    event.preventDefault();
    console.log("Logout event triggered");

    try {
      const response = await window.API.auth.logout();
      console.log("Logout API response:", response);

      // Redirect to home page
      window.location.href = "/";
    } catch (error) {
      console.error("Logout error:", error);
      // Still redirect to home page even if there's an error
      window.location.href = "/";
    }
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message;
      this.errorTarget.style.display = "block";
    } else {
      alert(message);
    }
  }
}
