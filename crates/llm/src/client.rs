use common::{NexusResult, NexusError};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::env;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ModelProvider {
    Ollama,
    OpenAI,
    Gemini,
    DeepSeek,
    Qwen,
}

impl std::fmt::Display for ModelProvider {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ModelProvider::Ollama => write!(f, "Ollama"),
            ModelProvider::OpenAI => write!(f, "OpenAI"),
            ModelProvider::Gemini => write!(f, "Gemini"),
            ModelProvider::DeepSeek => write!(f, "DeepSeek"),
            ModelProvider::Qwen => write!(f, "Qwen"),
        }
    }
}

pub struct LlmClient {
    client: Client,
    provider: ModelProvider,
    model: String,
    api_key: Option<String>,
}

impl LlmClient {
    pub fn new(provider: ModelProvider, model: &str) -> NexusResult<Self> {
        let client = Client::builder().build()
            .map_err(|e| NexusError::Config(format!("HTTP client error: {}", e)))?;

        let api_key = match provider {
            ModelProvider::Ollama => None,
            ModelProvider::OpenAI => env::var("OPENAI_API_KEY").ok(),
            ModelProvider::Gemini => env::var("GEMINI_API_KEY").ok(),
            ModelProvider::DeepSeek => env::var("DEEPSEEK_API_KEY").ok(),
            ModelProvider::Qwen => env::var("QWEN_API_KEY").ok(),
        };

        Ok(Self { client, provider, model: model.to_string(), api_key })
    }

    pub async fn ask(&self, prompt: &str) -> NexusResult<String> {
        match self.provider {
            ModelProvider::Ollama => self.ask_ollama(prompt).await,
            ModelProvider::OpenAI => self.ask_openai(prompt).await,
            ModelProvider::Gemini => self.ask_gemini(prompt).await,
            ModelProvider::DeepSeek => self.ask_deepseek(prompt).await,
            ModelProvider::Qwen => self.ask_qwen(prompt).await,
        }
    }

    async fn ask_ollama(&self, prompt: &str) -> NexusResult<String> {
        #[derive(Serialize)] struct Req { model: String, prompt: String, stream: bool }
        #[derive(Deserialize)] struct Res { response: String }
        
        let res = self.client.post("http://localhost:11434/api/generate")
            .json(&Req { model: self.model.clone(), prompt: prompt.to_string(), stream: false })
            .send().await.map_err(|e| NexusError::Config(e.to_string()))?;
            
        if !res.status().is_success() { return Err(NexusError::Config(format!("Ollama error: {}", res.status()))); }
        let data: Res = res.json().await.map_err(|e| NexusError::Config(e.to_string()))?;
        Ok(data.response)
    }

    async fn ask_openai(&self, prompt: &str) -> NexusResult<String> {
        let key = self.api_key.as_ref().ok_or_else(|| NexusError::Config("Missing OPENAI_API_KEY".to_string()))?;
        #[derive(Serialize)] struct Message { role: String, content: String }
        #[derive(Serialize)] struct Req { model: String, messages: Vec<Message> }
        #[derive(Deserialize)] struct Choice { message: Message }
        #[derive(Deserialize)] struct Res { choices: Vec<Choice> }

        let res = self.client.post("https://api.openai.com/v1/chat/completions")
            .header("Authorization", format!("Bearer {}", key))
            .json(&Req { 
                model: self.model.clone(), 
                messages: vec![Message { role: "user".to_string(), content: prompt.to_string() }] 
            }).send().await.map_err(|e| NexusError::Config(e.to_string()))?;
            
        if !res.status().is_success() { return Err(NexusError::Config(format!("OpenAI error: {}", res.status()))); }
        let data: Res = res.json().await.map_err(|e| NexusError::Config(e.to_string()))?;
        Ok(data.choices.first().map(|c| c.message.content.clone()).unwrap_or_default())
    }

    async fn ask_gemini(&self, prompt: &str) -> NexusResult<String> {
        let key = self.api_key.as_ref().ok_or_else(|| NexusError::Config("Missing GEMINI_API_KEY".to_string()))?;
        #[derive(Serialize)] struct Content { parts: Vec<Part> }
        #[derive(Serialize)] struct Part { text: String }
        #[derive(Serialize)] struct Req { contents: Vec<Content> }
        #[derive(Deserialize)] struct TextPart { text: String }
        #[derive(Deserialize)] struct Candidate { content: ContentResp }
        #[derive(Deserialize)] struct ContentResp { parts: Vec<TextPart> }
        #[derive(Deserialize)] struct Res { candidates: Vec<Candidate> }

        let url = format!("https://generativelanguage.googleapis.com/v1beta/models/{}:generateContent?key={}", self.model, key);
        let res = self.client.post(&url)
            .json(&Req { contents: vec![Content { parts: vec![Part { text: prompt.to_string() }] }] })
            .send().await.map_err(|e| NexusError::Config(e.to_string()))?;
            
        if !res.status().is_success() { return Err(NexusError::Config(format!("Gemini error: {}", res.status()))); }
        let data: Res = res.json().await.map_err(|e| NexusError::Config(e.to_string()))?;
        Ok(data.candidates.first()
            .and_then(|c| c.content.parts.first())
            .map(|p| p.text.clone())
            .unwrap_or_default())
    }

    // DeepSeek and Qwen use OpenAI-compatible API format
    async fn ask_deepseek(&self, prompt: &str) -> NexusResult<String> {
        let key = self.api_key.as_ref().ok_or_else(|| NexusError::Config("Missing DEEPSEEK_API_KEY".to_string()))?;
        #[derive(Serialize)] struct Msg { role: String, content: String }
        #[derive(Serialize)] struct Req { model: String, messages: Vec<Msg> }
        #[derive(Deserialize)] struct Ch { message: Msg }
        #[derive(Deserialize)] struct Res { choices: Vec<Ch> }

        let res = self.client.post("https://api.deepseek.com/v1/chat/completions")
            .header("Authorization", format!("Bearer {}", key))
            .json(&Req { model: self.model.clone(), messages: vec![Msg { role: "user".to_string(), content: prompt.to_string() }] })
            .send().await.map_err(|e| NexusError::Config(e.to_string()))?;
            
        let data: Res = res.json().await.map_err(|e| NexusError::Config(e.to_string()))?;
        Ok(data.choices.first().map(|c| c.message.content.clone()).unwrap_or_default())
    }

    async fn ask_qwen(&self, prompt: &str) -> NexusResult<String> {
        let key = self.api_key.as_ref().ok_or_else(|| NexusError::Config("Missing QWEN_API_KEY".to_string()))?;
        #[derive(Serialize)] struct Msg { role: String, content: String }
        #[derive(Serialize)] struct Req { model: String, messages: Vec<Msg> }
        #[derive(Deserialize)] struct Ch { message: Msg }
        #[derive(Deserialize)] struct Res { choices: Vec<Ch> }

        let res = self.client.post("https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions")
            .header("Authorization", format!("Bearer {}", key))
            .json(&Req { model: self.model.clone(), messages: vec![Msg { role: "user".to_string(), content: prompt.to_string() }] })
            .send().await.map_err(|e| NexusError::Config(e.to_string()))?;
            
        let data: Res = res.json().await.map_err(|e| NexusError::Config(e.to_string()))?;
        Ok(data.choices.first().map(|c| c.message.content.clone()).unwrap_or_default())
    }
}
