// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "controllers";
import API from "./api";

// Make API available globally for the auth controller to use
window.API = API;
