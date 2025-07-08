// API service for connecting to the RAG backend
import config from './config';

class ApiService {
  constructor() {
    this.baseUrl = config.API_BASE_URL;
    console.log('🔗 ApiService initialized with baseUrl:', this.baseUrl);
  }

  async query(text) {
    try {
      const url = `${this.baseUrl}${config.endpoints.query}`;
      console.log('📡 Making query request to:', url);
      console.log('📝 Query payload:', { text });
      
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ text }),
      });

      console.log('📡 Query response status:', response.status);

      if (!response.ok) {
        const errorText = await response.text();
        console.error('❌ Query failed:', response.status, errorText);
        throw new Error(`HTTP error! status: ${response.status} - ${errorText}`);
      }

      // The endpoint returns a string directly
      const answer = await response.text();
      console.log('✅ Query response received:', answer.substring(0, 100) + '...');
      return answer;
    } catch (error) {
      console.error('Error querying RAG pipeline:', error);
      throw error;
    }
  }

  async uploadDocument(file) {
    try {
      const formData = new FormData();
      formData.append('file', file);

      const response = await fetch(`${this.baseUrl}${config.endpoints.documents}`, {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Error uploading document:', error);
      throw error;
    }
  }

  async checkHealth() {
    try {
      const url = `${this.baseUrl}${config.endpoints.health}`;
      console.log('🏥 Making health check request to:', url);
      
      const response = await fetch(url);
      console.log('🏥 Health check response status:', response.status);
      return response.ok;
    } catch (error) {
      console.error('Health check failed:', error);
      return false;
    }
  }

  async getDocuments() {
    try {
      const response = await fetch(`${this.baseUrl}${config.endpoints.documents}`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.json();
    } catch (error) {
      console.error('Error fetching documents:', error);
      throw error;
    }
  }

  async getTranscriptions() {
    try {
      const response = await fetch(`${this.baseUrl}${config.endpoints.transcriptions}`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.json();
    } catch (error) {
      console.error('Error fetching transcriptions:', error);
      throw error;
    }
  }
}

export default new ApiService();
