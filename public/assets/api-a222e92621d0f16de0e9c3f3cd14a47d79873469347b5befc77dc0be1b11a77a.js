// API client for making requests to the backend
const API = {
  // Authentication methods
  auth: {
    login: async (email, password) => {
      const response = await fetch("/api/v1/auth/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]')
            ?.content,
        },
        body: JSON.stringify({ email, password }),
      });
      return response.json();
    },

    signup: async userData => {
      const response = await fetch("/api/v1/auth/signup", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]')
            ?.content,
        },
        body: JSON.stringify(userData),
      });
      return response.json();
    },

    logout: async () => {
      const response = await fetch("/api/v1/auth/logout", {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]')
            ?.content,
        },
      });
      return response.json();
    },
  },

  // Asset methods
  assets: {
    list: async () => {
      const response = await fetch("/api/v1/assets", {
        headers: {
          "Content-Type": "application/json",
        },
      });
      return response.json();
    },

    get: async id => {
      const response = await fetch(`/api/v1/assets/${id}`, {
        headers: {
          "Content-Type": "application/json",
        },
      });
      return response.json();
    },

    create: async assetData => {
      const response = await fetch("/api/v1/assets", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]')
            ?.content,
        },
        body: JSON.stringify({ asset: assetData }),
      });
      return response.json();
    },

    update: async (id, assetData) => {
      const response = await fetch(`/api/v1/assets/${id}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]')
            ?.content,
        },
        body: JSON.stringify({ asset: assetData }),
      });
      return response.json();
    },

    delete: async id => {
      const response = await fetch(`/api/v1/assets/${id}`, {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]')
            ?.content,
        },
      });
      return response.json();
    },

    getValue: async id => {
      const response = await fetch(`/api/v1/assets/${id}/value`, {
        headers: {
          "Content-Type": "application/json",
        },
      });
      return response.json();
    },
  },

  // Transaction methods
  transactions: {
    list: async () => {
      const response = await fetch("/api/v1/transactions", {
        headers: {
          "Content-Type": "application/json",
        },
      });
      return response.json();
    },

    get: async id => {
      const response = await fetch(`/api/v1/transactions/${id}`, {
        headers: {
          "Content-Type": "application/json",
        },
      });
      return response.json();
    },

    create: async transactionData => {
      const response = await fetch("/api/v1/transactions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]')
            ?.content,
        },
        body: JSON.stringify({ transaction: transactionData }),
      });
      return response.json();
    },
  },
};

export default API;
