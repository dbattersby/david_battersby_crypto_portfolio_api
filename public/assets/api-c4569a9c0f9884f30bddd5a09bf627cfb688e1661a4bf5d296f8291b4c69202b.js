// API utility for portfolio management

const API = {
  // Get CSRF token from meta tag
  getCSRFToken() {
    return document
      .querySelector('meta[name="csrf-token"]')
      .getAttribute("content");
  },

  // Fetch headers with authentication
  headers() {
    return {
      "Content-Type": "application/json",
      "X-CSRF-Token": this.getCSRFToken(),
      Accept: "application/json",
    };
  },

  // Handle API response
  async handleResponse(response) {
    try {
      const data = await response.json();
      console.log("API response data:", data);

      if (!response.ok) {
        const error = data.message || data.error || response.statusText;
        console.error("API error:", error, data);
        return Promise.reject(error);
      }

      return data;
    } catch (error) {
      console.error("Failed to parse API response:", error);
      return Promise.reject("Failed to process response from server");
    }
  },

  // Get all assets
  async getAssets() {
    console.log("Fetching assets from API...");
    try {
      const response = await fetch("/api/v1/portfolio", {
        method: "GET",
        headers: this.headers(),
        credentials: "include", // Include cookies
      });
      console.log("Raw API response:", response.status, response.statusText);
      return this.handleResponse(response);
    } catch (error) {
      console.error("Network error fetching assets:", error);
      return Promise.reject(error);
    }
  },

  // Get asset by symbol
  async getAssetBySymbol(symbol) {
    const response = await fetch(`/api/v1/portfolio/transactions/${symbol}`, {
      method: "GET",
      headers: this.headers(),
    });
    return this.handleResponse(response);
  },

  // Create a new asset
  async createAsset(assetData) {
    const response = await fetch("/api/v1/portfolio/create", {
      method: "POST",
      headers: this.headers(),
      body: JSON.stringify({ asset: assetData }),
    });
    return this.handleResponse(response);
  },

  // Add transaction to existing asset
  async addTransaction(assetData) {
    const response = await fetch("/api/v1/portfolio/add_transaction", {
      method: "POST",
      headers: this.headers(),
      body: JSON.stringify({ asset: assetData }),
    });
    return this.handleResponse(response);
  },

  // Sell asset
  async sellAsset(transactionData) {
    const response = await fetch("/api/v1/portfolio/create_sell", {
      method: "POST",
      headers: this.headers(),
      body: JSON.stringify({ transaction: transactionData }),
    });
    return this.handleResponse(response);
  },

  // Get transactions by symbol
  async getTransactionsBySymbol(symbol) {
    const response = await fetch(`/api/v1/portfolio/transactions/${symbol}`, {
      method: "GET",
      headers: this.headers(),
    });
    return this.handleResponse(response);
  },

  // Get all transactions
  async getTransactions() {
    const response = await fetch("/api/v1/transactions", {
      method: "GET",
      headers: this.headers(),
    });
    return this.handleResponse(response);
  },

  // Get transaction by ID
  async getTransaction(id) {
    const response = await fetch(`/api/v1/transactions/${id}`, {
      method: "GET",
      headers: this.headers(),
    });
    return this.handleResponse(response);
  },

  // Update transaction
  async updateTransaction(id, transactionData) {
    const response = await fetch(`/api/v1/transactions/${id}`, {
      method: "PATCH",
      headers: this.headers(),
      body: JSON.stringify({ transaction: transactionData }),
    });
    return this.handleResponse(response);
  },

  // Delete transaction
  async deleteTransaction(id) {
    const response = await fetch(`/api/v1/transactions/${id}`, {
      method: "DELETE",
      headers: this.headers(),
    });
    return this.handleResponse(response);
  },
};

export default API;
