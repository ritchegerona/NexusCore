use common::{NexusError, NexusResult};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Workspace {
    pub name: String,
    pub path: PathBuf,
    pub created_at: String,
}

impl Workspace {
    pub fn new(name: &str, path: &str) -> NexusResult<Self> {
        let workspace = Self {
            name: name.to_string(),
            path: PathBuf::from(path),
            created_at: chrono::Utc::now().to_rfc3339(),
        };

        // Create workspace directory
        filesystem::create_dir(path)?;

        tracing::info!("Workspace '{}' created at {:?}", name, path);
        Ok(workspace)
    }

    pub fn save(&self, config_path: &str) -> NexusResult<()> {
        let content = serde_json::to_string_pretty(self)
            .map_err(|e| NexusError::Config(format!("Failed to serialize workspace: {}", e)))?;

        filesystem::write_file(config_path, &content)?;
        tracing::info!("Workspace config saved to {}", config_path);
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use filesystem::file_exists;
    use std::fs;

    #[test]
    fn test_workspace_creation() {
        let test_path = "test_workspace";
        let ws = Workspace::new("test-ws", test_path).unwrap();

        assert_eq!(ws.name, "test-ws");
        assert!(file_exists(test_path));

        fs::remove_dir_all(test_path).unwrap();
    }

    #[test]
    fn test_workspace_save() {
        let test_path = "test_ws_save";
        let ws = Workspace::new("save-test", test_path).unwrap();

        let config_path = format!("{}/workspace.json", test_path);
        ws.save(&config_path).unwrap();

        assert!(file_exists(&config_path));

        fs::remove_dir_all(test_path).unwrap();
    }
}
