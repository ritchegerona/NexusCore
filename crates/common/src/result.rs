use crate::error::NexusError;

pub type NexusResult<T> = std::result::Result<T, NexusError>;
