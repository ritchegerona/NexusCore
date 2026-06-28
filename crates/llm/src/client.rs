use common::{NexusResult, NexusError};
use reqwest::Client;
use serde::{Deserialize, Serialize};

const OLLAMA_BASE_URL: &str = "http://localhost:11434";

#[derive(Debug, Serialize)]
struct GenerateRequest {
    model: String,
    prompt: String,
    stream: bool,
}

#[derive(Debug, Deserialize)]
struct GenerateResponse {
    response: String,
}

pub struct OllamaClient {
    client: Client,
    model: String,
}

impl OllamaClient {
    pub fn new(model: &str) -> NexusResult<Self> {
        let client = Client::builder()
            .build()
            .map_err(|e| NexusError::Config(format!("Failed to create HTTP client: {}", e)))?;

        Ok(Self {
            client,
            model: model.to_string(),
        })
    }

    pub async fn ask(&self, prompt: &str) -> NexusResult<String> {
        let url = format!("{}/api/generate", OLLAMA_BASE_URL);
        tracing::debug!("Sending prompt to Ollama: {}", self.model);

        let request = GenerateRequest {
            model: self.model.clone(),
            prompt: prompt.to_string(),
            stream: false,
        };

        let response = self.client
            .post(&url)
            .json(&request)
            .send()
            .await
            .map_err(|e| NexusError::Config(format!("Failed to connect to Ollama: {}", e)))?;

        if !response.status().is_success() {
            return Err(NexusError::Config(format!("Ollama API error: {}", response.status())));
        }

        let result: GenerateResponse = response
            .json()
            .await
            .map_err(|e| NexusError::Config(format!("Failed to parse response: {}", e)))?;

        Ok(result.response)
    }
}
