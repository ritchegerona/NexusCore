use common::{NexusResult, NexusError};
use reqwest::Client;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub message: Option<String>,
}

pub struct HttpClient {
    client: Client,
    base_url: String,
}

impl HttpClient {
    pub fn new(base_url: &str) -> NexusResult<Self> {
        let client = Client::builder()
            .build()
            .map_err(|e| NexusError::Config(format!("Failed to create HTTP client: {}", e)))?;

        Ok(Self {
            client,
            base_url: base_url.to_string(),
        })
    }

    pub async fn get<T: for<'de> Deserialize<'de>>(&self, endpoint: &str) -> NexusResult<T> {
        let url = format!("{}{}", self.base_url, endpoint);
        tracing::debug!("GET request to: {}", url);

        let response = self.client
            .get(&url)
            .send()
            .await
            .map_err(|e| NexusError::Config(format!("HTTP GET failed: {}", e)))?;

        if !response.status().is_success() {
            return Err(NexusError::Config(format!(
                "HTTP error: {}",
                response.status()
            )));
        }

        let data = response
            .json::<T>()
            .await
            .map_err(|e| NexusError::Config(format!("Failed to parse JSON: {}", e)))?;

        Ok(data)
    }

    pub async fn post<T: Serialize, R: for<'de> Deserialize<'de>>(
        &self,
        endpoint: &str,
        body: &T,
    ) -> NexusResult<R> {
        let url = format!("{}{}", self.base_url, endpoint);
        tracing::debug!("POST request to: {}", url);

        let response = self.client
            .post(&url)
            .json(body)
            .send()
            .await
            .map_err(|e| NexusError::Config(format!("HTTP POST failed: {}", e)))?;

        if !response.status().is_success() {
            return Err(NexusError::Config(format!(
                "HTTP error: {}",
                response.status()
            )));
        }

        let data = response
            .json::<R>()
            .await
            .map_err(|e| NexusError::Config(format!("Failed to parse JSON: {}", e)))?;

        Ok(data)
    }
}
