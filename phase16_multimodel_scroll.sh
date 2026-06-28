#!/usr/bin/env bash
set -e

echo "🚀 Initializing Phase 16: Multi-Model Support & Scroll Fix..."

# 1. Update LLM Crate for Multi-Model Support
cat > crates/llm/src/client.rs <<'EOF'
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
EOF

# 2. Update lib.rs to export new types
cat > crates/llm/src/lib.rs <<'EOF'
pub mod client;
pub use client::{LlmClient, ModelProvider};
EOF

# 3. Update Dashboard HTML with FIXED SCROLLING & MODEL SELECTOR
cat > crates/dashboard/static/index.html <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexusCore Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/lucide@latest"></script>
    <script src="https://cdn.jsdelivr.net/npm/axios@1.6.8/dist/axios.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; }
        /* CRITICAL SCROLL FIX */
        #chat-history { 
            overflow-y: auto !important; 
            max-height: calc(100vh - 280px); 
            scrollbar-gutter: stable;
        }
        .code-block { font-family: 'JetBrains Mono', monospace; background: #0f172a; border-left: 3px solid #3b82f6; white-space: pre-wrap; word-break: break-word; }
        .chat-message pre { background: #0f172a; border-radius: 8px; padding: 1rem; overflow-x: auto; margin: 0.5rem 0; border: 1px solid #1e293b; }
        .chat-message code { font-family: 'JetBrains Mono', monospace; font-size: 0.8rem; color: #e2e8f0; }
        .chat-message p { margin-bottom: 0.75rem; line-height: 1.7; }
        .glass-panel { background: rgba(30, 41, 59, 0.6); backdrop-filter: blur(16px); border: 1px solid rgba(148, 163, 184, 0.08); }
        .agent-btn.active { background: rgba(59, 130, 246, 0.2); border-color: rgba(59, 130, 246, 0.5); }
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #475569; border-radius: 3px; }
    </style>
</head>
<body class="bg-slate-950 text-slate-200 h-screen flex flex-col overflow-hidden">
    <!-- Header -->
    <header class="border-b border-slate-800/80 px-6 py-3 flex-shrink-0 bg-slate-950/80 backdrop-blur-md z-20">
        <div class="flex items-center justify-between max-w-[1920px] mx-auto">
            <div class="flex items-center gap-3">
                <img src="/static/assets/logo.png" alt="NexusCore" class="w-9 h-9">
                <div><h1 class="text-lg font-semibold text-white tracking-tight leading-none">NexusCore</h1><p class="text-[10px] text-slate-500 font-medium tracking-[0.2em] uppercase mt-0.5">Agents · Connect · Create</p></div>
            </div>
            <div class="flex items-center gap-3">
                <span class="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-500/10 text-emerald-400 text-[11px] font-medium border border-emerald-500/20"><span class="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>Online</span>
                <span class="text-[11px] text-slate-600 font-mono">v0.1.0</span>
            </div>
        </div>
    </header>

    <!-- Main Layout -->
    <main class="flex-1 flex max-w-[1920px] mx-auto w-full p-4 gap-4 min-h-0 overflow-hidden">
        <!-- Left Panel -->
        <section class="w-[400px] flex-shrink-0 flex flex-col gap-4 overflow-y-auto pr-1">
            <div class="grid grid-cols-3 gap-3">
                <div class="glass-panel rounded-xl p-4 text-center"><p class="text-[10px] text-slate-500 uppercase tracking-wider mb-1">Crates</p><p class="text-xl font-bold text-white">7</p></div>
                <div class="glass-panel rounded-xl p-4 text-center"><p class="text-[10px] text-slate-500 uppercase tracking-wider mb-1">Tests</p><p class="text-xl font-bold text-emerald-400">11</p></div>
                <div class="glass-panel rounded-xl p-4 text-center"><p class="text-[10px] text-slate-500 uppercase tracking-wider mb-1">Agents</p><p class="text-xl font-bold text-blue-400">4</p></div>
            </div>
            <div class="glass-panel rounded-xl p-4 space-y-2">
                <p class="text-[10px] font-semibold text-slate-500 uppercase tracking-wider mb-3 px-1">Quick Actions</p>
                <button onclick="buildWorkspace()" class="w-full flex items-center gap-3 p-3 rounded-lg bg-slate-800/40 hover:bg-blue-600/15 border border-slate-700/40 hover:border-blue-500/40 transition-all text-left group"><div class="w-8 h-8 rounded-md bg-blue-500/10 flex items-center justify-center group-hover:bg-blue-500/20"><i data-lucide="hammer" class="w-4 h-4 text-blue-400"></i></div><div><p class="text-sm font-medium text-slate-200">Build Workspace</p><p class="text-[10px] text-slate-500">Compile all crates</p></div></button>
                <button onclick="runTests()" class="w-full flex items-center gap-3 p-3 rounded-lg bg-slate-800/40 hover:bg-emerald-600/15 border border-slate-700/40 hover:border-emerald-500/40 transition-all text-left group"><div class="w-8 h-8 rounded-md bg-emerald-500/10 flex items-center justify-center group-hover:bg-emerald-500/20"><i data-lucide="flask-conical" class="w-4 h-4 text-emerald-400"></i></div><div><p class="text-sm font-medium text-slate-200">Run Tests</p><p class="text-[10px] text-slate-500">Execute test suite</p></div></button>
                <button onclick="openDocs()" class="w-full flex items-center gap-3 p-3 rounded-lg bg-slate-800/40 hover:bg-purple-600/15 border border-slate-700/40 hover:border-purple-500/40 transition-all text-left group"><div class="w-8 h-8 rounded-md bg-purple-500/10 flex items-center justify-center group-hover:bg-purple-500/20"><i data-lucide="book-open" class="w-4 h-4 text-purple-400"></i></div><div><p class="text-sm font-medium text-slate-200">Documentation</p><p class="text-[10px] text-slate-500">Open API docs</p></div></button>
            </div>
            <div class="glass-panel rounded-xl p-4 flex-1">
                <p class="text-[10px] font-semibold text-slate-500 uppercase tracking-wider mb-3 px-1">System</p>
                <div class="space-y-2 text-xs">
                    <div class="flex justify-between p-2 bg-slate-800/30 rounded"><span class="text-slate-500">Edition</span><span class="text-slate-300 font-mono">2021</span></div>
                    <div class="flex justify-between p-2 bg-slate-800/30 rounded"><span class="text-slate-500">Runtime</span><span class="text-slate-300 font-mono">Tokio</span></div>
                    <div class="flex justify-between p-2 bg-slate-800/30 rounded"><span class="text-slate-500">Framework</span><span class="text-slate-300 font-mono">Axum</span></div>
                </div>
            </div>
        </section>

        <!-- Right Panel: Chat with FIXED SCROLL -->
        <section class="flex-1 flex flex-col glass-panel rounded-xl overflow-hidden min-w-0">
            <!-- Tabs -->
            <div class="flex items-center gap-1 p-3 border-b border-slate-700/40 bg-slate-900/30 overflow-x-auto flex-shrink-0">
                <button onclick="selectAgent('general')" class="agent-btn active flex items-center gap-2 px-4 py-2 rounded-lg border border-transparent hover:bg-slate-800/60 transition-all text-sm whitespace-nowrap" data-agent="general"><i data-lucide="bot" class="w-4 h-4 text-cyan-400"></i><span class="font-medium">General</span></button>
                <div class="w-px h-6 bg-slate-700/50 mx-1"></div>
                <button onclick="selectAgent('architect')" class="agent-btn flex items-center gap-2 px-4 py-2 rounded-lg border border-transparent hover:bg-slate-800/60 transition-all text-sm whitespace-nowrap" data-agent="architect"><i data-lucide="compass" class="w-4 h-4 text-blue-400"></i><span class="font-medium">Architect</span></button>
                <button onclick="selectAgent('coder')" class="agent-btn flex items-center gap-2 px-4 py-2 rounded-lg border border-transparent hover:bg-slate-800/60 transition-all text-sm whitespace-nowrap" data-agent="coder"><i data-lucide="code" class="w-4 h-4 text-emerald-400"></i><span class="font-medium">Coder</span></button>
                <button onclick="selectAgent('reviewer')" class="agent-btn flex items-center gap-2 px-4 py-2 rounded-lg border border-transparent hover:bg-slate-800/60 transition-all text-sm whitespace-nowrap" data-agent="reviewer"><i data-lucide="search-check" class="w-4 h-4 text-amber-400"></i><span class="font-medium">Reviewer</span></button>
                <button onclick="selectAgent('researcher')" class="agent-btn flex items-center gap-2 px-4 py-2 rounded-lg border border-transparent hover:bg-slate-800/60 transition-all text-sm whitespace-nowrap" data-agent="researcher"><i data-lucide="book-open" class="w-4 h-4 text-purple-400"></i><span class="font-medium">Researcher</span></button>
                
                <!-- MODEL SELECTOR -->
                <div class="ml-auto flex items-center gap-2 pl-4 border-l border-slate-700/50">
                    <i data-lucide="cpu" class="w-4 h-4 text-slate-500"></i>
                    <select id="model-select" onchange="changeModel(this.value)" class="bg-slate-800 text-slate-300 text-xs rounded-md px-2 py-1.5 border border-slate-700 focus:outline-none focus:border-blue-500 cursor-pointer">
                        <option value="ollama:gemma:2b-instruct">Ollama (Gemma 2B)</option>
                        <option value="openai:gpt-4o-mini">OpenAI (GPT-4o Mini)</option>
                        <option value="gemini:gemini-1.5-flash">Google Gemini 1.5 Flash</option>
                        <option value="deepseek:deepseek-chat">DeepSeek Chat</option>
                        <option value="qwen:qwen-max">Qwen Max</option>
                    </select>
                </div>
            </div>

            <!-- Agent Info -->
            <div id="agent-info" class="px-5 py-2.5 bg-gradient-to-r from-cyan-500/5 to-transparent border-b border-slate-800/40 flex items-center gap-3 flex-shrink-0">
                <div id="agent-icon" class="w-7 h-7 rounded-md bg-cyan-500/15 flex items-center justify-center"><i data-lucide="bot" class="w-3.5 h-3.5 text-cyan-400"></i></div>
                <div><p id="agent-name" class="text-sm font-semibold text-white">General Assistant</p><p id="agent-desc" class="text-[11px] text-slate-500">Multi-purpose AI assistant for NexusCore</p></div>
            </div>

            <!-- CHAT AREA WITH DEDICATED SCROLL -->
            <div id="chat-history" class="flex-1 overflow-y-auto p-5 space-y-5 scroll-smooth">
                <div class="flex gap-3">
                    <div class="w-7 h-7 rounded-md bg-gradient-to-br from-cyan-500 to-blue-600 flex-shrink-0 flex items-center justify-center mt-0.5"><i data-lucide="bot" class="w-3.5 h-3.5 text-white"></i></div>
                    <div class="chat-message flex-1 min-w-0"><p class="text-[10px] text-slate-500 mb-1 font-medium">NexusCore AI</p><div class="text-slate-300 text-sm">Welcome! Select an agent or model above. The chat window now has independent scrolling.</div></div>
                </div>
            </div>

            <!-- Input -->
            <div class="p-4 border-t border-slate-700/40 bg-slate-900/40 flex-shrink-0">
                <div class="flex gap-2">
                    <input type="text" id="chat-input" class="flex-1 bg-slate-800/80 text-white px-4 py-2.5 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/40 placeholder-slate-500 text-sm border border-slate-700/50" placeholder="Ask the selected agent..." onkeypress="if(event.key==='Enter')sendChat()">
                    <button onclick="sendChat()" class="px-5 py-2.5 bg-blue-600 hover:bg-blue-500 rounded-lg transition-colors font-medium text-sm flex items-center gap-2">Send <i data-lucide="send" class="w-3.5 h-3.5"></i></button>
                </div>
            </div>
        </section>
    </main>

    <script>
        lucide.createIcons();
        marked.setOptions({ breaks: true, gfm: true });
        let currentAgent = 'general';
        let currentModel = 'ollama:gemma:2b-instruct';
        const agentMeta = {
            general: { name: 'General Assistant', desc: 'Multi-purpose AI assistant', icon: 'bot', color: 'cyan' },
            architect: { name: 'Architect Agent', desc: 'System design & architecture', icon: 'compass', color: 'blue' },
            coder: { name: 'Coder Agent', desc: 'Rust code generation', icon: 'code', color: 'emerald' },
            reviewer: { name: 'Reviewer Agent', desc: 'Code review & quality', icon: 'search-check', color: 'amber' },
            researcher: { name: 'Researcher Agent', desc: 'Tech research & docs', icon: 'book-open', color: 'purple' }
        };

        function selectAgent(agent) {
            currentAgent = agent;
            document.querySelectorAll('.agent-btn').forEach(b => b.classList.remove('active'));
            document.querySelector(`[data-agent="${agent}"]`)?.classList.add('active');
            const meta = agentMeta[agent];
            document.getElementById('agent-name').textContent = meta.name;
            document.getElementById('agent-desc').textContent = meta.desc;
            document.getElementById('agent-icon').innerHTML = `<i data-lucide="${meta.icon}" class="w-3.5 h-3.5 text-${meta.color}-400"></i>`;
            document.getElementById('agent-icon').className = `w-7 h-7 rounded-md bg-${meta.color}-500/15 flex items-center justify-center`;
            document.getElementById('chat-input').placeholder = `Ask ${meta.name}...`;
            document.getElementById('chat-input').focus();
            lucide.createIcons();
        }

        function changeModel(val) { currentModel = val; console.log('Model changed to:', val); }

        function formatMessage(text) {
            let html = marked.parse(text);
            html = html.replace(/<pre><code class="language-(\w+)">/g, '<pre class="code-block"><code class="language-$1">');
            html = html.replace(/<pre><code>/g, '<pre class="code-block"><code>');
            return html;
        }

        function addMessage(role, content, isUser = false) {
            const history = document.getElementById('chat-history');
            const time = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            const meta = agentMeta[currentAgent];
            if (isUser) {
                history.innerHTML += `<div class="flex gap-3 flex-row-reverse"><div class="w-7 h-7 rounded-md bg-slate-700 flex-shrink-0 flex items-center justify-center mt-0.5"><i data-lucide="user" class="w-3.5 h-3.5 text-slate-300"></i></div><div class="flex-1 text-right min-w-0"><p class="text-[10px] text-slate-500 mb-1">You · ${time}</p><div class="inline-block bg-blue-600/15 text-blue-100 px-4 py-2 rounded-2xl rounded-tr-sm text-sm text-left break-words">${content}</div></div></div>`;
            } else {
                const label = currentAgent === 'general' ? 'NexusCore AI' : meta.name;
                history.innerHTML += `<div class="flex gap-3"><div class="w-7 h-7 rounded-md bg-gradient-to-br from-${meta.color}-500 to-${meta.color}-600 flex-shrink-0 flex items-center justify-center mt-0.5"><i data-lucide="${meta.icon}" class="w-3.5 h-3.5 text-white"></i></div><div class="chat-message flex-1 min-w-0"><p class="text-[10px] text-slate-500 mb-1 font-medium">${label} · ${time}</p><div class="text-slate-300 text-sm break-words">${formatMessage(content)}</div></div></div>`;
            }
            // Smooth scroll to bottom
            history.scrollTo({ top: history.scrollHeight, behavior: 'smooth' });
            lucide.createIcons();
        }

        async function sendChat() {
            const input = document.getElementById('chat-input');
            const message = input.value.trim();
            if (!message) return;
            addMessage('user', message, true);
            input.value = '';
            const history = document.getElementById('chat-history');
            const tid = 'typing-' + Date.now();
            const meta = agentMeta[currentAgent];
            history.innerHTML += `<div id="${tid}" class="flex gap-3"><div class="w-7 h-7 rounded-md bg-${meta.color}-500/15 flex-shrink-0 flex items-center justify-center mt-0.5"><i data-lucide="${meta.icon}" class="w-3.5 h-3.5 text-${meta.color}-400"></i></div><div class="flex-1"><p class="text-[10px] text-slate-500 mb-1 font-medium">${meta.name}</p><div class="flex gap-1 text-slate-600 text-sm"><span class="animate-bounce">●</span><span class="animate-bounce" style="animation-delay:.1s">●</span><span class="animate-bounce" style="animation-delay:.2s">●</span></div></div></div>`;
            history.scrollTo({ top: history.scrollHeight, behavior: 'smooth' });
            
            try {
                const [provider, modelName] = currentModel.split(':');
                let res;
                if (currentAgent === 'general') { 
                    res = await axios.post('/api/chat', { message, provider, model: modelName }); 
                } else { 
                    res = await axios.post('/api/agents/chat', { agent: currentAgent, message, provider, model: modelName }); 
                }
                addMessage('ai', res.data.response);
            } catch (e) { addMessage('ai', `⚠️ Error: ${e.response?.data || e.message}`); }
            document.getElementById(tid)?.remove();
        }

        async function buildWorkspace() { try { await axios.get('/api/build'); } catch(e) { console.error(e); } }
        async function runTests() { try { await axios.get('/api/test'); } catch(e) { console.error(e); } }
        async function openDocs() { try { await axios.get('/api/docs'); } catch(e) { console.error(e); } }
        document.addEventListener('DOMContentLoaded', () => { document.getElementById('chat-input').focus(); });
    </script>
</body>
</html>
HTMLEOF

# 4. Update dashboard handlers to accept provider/model params
sed -i '' 's/pub struct ChatRequest {/pub struct ChatRequest {\n    pub provider: Option<String>,\n    pub model: Option<String>,/' crates/dashboard/src/handlers.rs

# Add multi-model logic to chat handler
sed -i '' '/let client = llm::OllamaClient::new/c\
    let provider_str = req.provider.unwrap_or_else(|| "ollama".to_string());\
    let model_name = req.model.unwrap_or_else(|| "gemma:2b-instruct".to_string());\
    let provider = match provider_str.to_lowercase().as_str() {\
        "openai" => llm::ModelProvider::OpenAI,\
        "gemini" => llm::ModelProvider::Gemini,\
        "deepseek" => llm::ModelProvider::DeepSeek,\
        "qwen" => llm::ModelProvider::Qwen,\
        _ => llm::ModelProvider::Ollama,\
    };\
    let client = llm::LlmClient::new(provider, \&model_name).unwrap();' crates/dashboard/src/handlers.rs

# Do same for agent_chat handler
sed -i '' '/let agent_result = match req.agent/i\
    let provider_str = req.provider.clone().unwrap_or_else(|| "ollama".to_string());\
    let model_name = req.model.clone().unwrap_or_else(|| "gemma:2b-instruct".to_string());\
    let provider = match provider_str.to_lowercase().as_str() {\
        "openai" => llm::ModelProvider::OpenAI,\
        "gemini" => llm::ModelProvider::Gemini,\
        "deepseek" => llm::ModelProvider::DeepSeek,\
        "qwen" => llm::ModelProvider::Qwen,\
        _ => llm::ModelProvider::Ollama,\
    };' crates/dashboard/src/handlers.rs

sed -i '' 's/architect_agent("gemma:2b-instruct")/architect_agent(\&model_name)/' crates/dashboard/src/handlers.rs
sed -i '' 's/coder_agent("gemma:2b-instruct")/coder_agent(\&model_name)/' crates/dashboard/src/handlers.rs
sed -i '' 's/reviewer_agent("gemma:2b-instruct")/reviewer_agent(\&model_name)/' crates/dashboard/src/handlers.rs
sed -i '' 's/researcher_agent("gemma:2b-instruct")/researcher_agent(\&model_name)/' crates/dashboard/src/handlers.rs

echo "✅ Phase 16 Complete!"
echo ""
echo "✨ New Features:"
echo "  • Fixed chat scrolling (independent scroll area)"
echo "  • Model selector dropdown (Ollama, OpenAI, Gemini, DeepSeek, Qwen)"
echo "  • Multi-provider LLM client in backend"
echo ""
echo "⚙️ Setup API Keys (create .env file):"
echo "  OPENAI_API_KEY=sk-..."
echo "  GEMINI_API_KEY=AIza..."
echo "  DEEPSEEK_API_KEY=sk-..."
echo "  QWEN_API_KEY=sk-..."
echo ""
echo "🚀 Restart: cargo run -p dashboard-server"