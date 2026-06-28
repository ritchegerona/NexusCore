use serde::Deserialize;

#[derive(Debug, Deserialize, Clone)]
pub struct NexusConfig {
    pub app_name: String,
    pub log_level: String,
    pub max_workers: Option<u32>,
}

impl Default for NexusConfig {
    fn default() -> Self {
        Self {
            app_name: "NexusCore".to_string(),
            log_level: "info".to_string(),
            max_workers: Some(4),
        }
    }
}
