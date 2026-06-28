#!/usr/bin/env bash
set -e

echo "🤖 Initializing Phase 15: Agent UI Integration..."

# 1. Add agent endpoints to dashboard handlers
cat >> crates/dashboard/src/handlers.rs <<'EOF'

// --- AGENT ENDPOINTS ---

#[derive(Deserialize)]
pub struct AgentChatRequest {
    pub agent: String,
    pub message: String,
}

pub async fn list_agents() -> Json<serde_json::Value> {
    let agents = serde_json::json!([
        { "name": "Architect", "role": "System Design & Architecture", "icon": "compass", "color": "blue" },
        { "name": "Coder", "role": "Rust Code Generation", "icon": "code", "color": "emerald" },
        { "name": "Reviewer", "role": "Code Review & Quality", "icon": "search-check", "color": "amber" },
        { "name": "Researcher", "role": "Technology Research", "icon": "book-open", "color": "purple" }
    ]);
    Json(agents)
}

pub async fn agent_chat(Json(req): Json<AgentChatRequest>) -> Response {
    use agents::presets::*;
    
    let agent_result = match req.agent.to_lowercase().as_str() {
        "architect" => architect_agent("gemma:2b-instruct"),
        "coder" => coder_agent("gemma:2b-instruct"),
        "reviewer" => reviewer_agent("gemma:2b-instruct"),
        "researcher" => researcher_agent("gemma:2b-instruct"),
        _ => return (StatusCode::BAD_REQUEST, format!("Unknown agent: {}", req.agent)).into_response(),
    };

    match agent_result {
        Ok(agent) => {
            match agent.think(&req.message).await {
                Ok(response) => Json(serde_json::json!({
                    "agent": req.agent,
                    "response": response,
                    "status": "success"
                })).into_response(),
                Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, format!("Agent error: {}", e)).into_response(),
            }
        }
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to create agent: {}", e)).into_response(),
    }
}
EOF

# 2. Register new routes in lib.rs
sed -i '' 's|.route("/api/logs/ws", get(handlers::logs_websocket))|.route("/api/logs/ws", get(handlers::logs_websocket))\n        .route("/api/agents", get(handlers::list_agents))\n        .route("/api/agents/chat", post(handlers::agent_chat))|' crates/dashboard/src/lib.rs

# 3. Update Dashboard HTML with Agent Panel
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
        .code-block { font-family: 'JetBrains Mono', monospace; background: #0f172a; border-left: 3px solid #3b82f6; }
        .chat-message pre { background: #0f172a; border-radius: 8px; padding: 1rem; overflow-x: auto; margin: 0.5rem 0; border: 1px solid #1e293b; }
        .chat-message code { font-family: 'JetBrains Mono', monospace; font-size: 0.8rem; color: #e2e8f0; }
        .chat-message p { margin-bottom: 0.75rem; line-height: 1.7; }
        .glass-panel { background: rgba(30, 41, 59, 0.6); backdrop-filter: blur(16px); border: 1px solid rgba(148, 163, 184, 0.08); }
        .agent-btn.active { background: rgba(59, 130, 246, 0.2); border-color: rgba(59, 130, 246, 0.5); }
        ::-webkit-scrollbar { width: 5px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #334155; border-radius: 3px; }
    </style>
</head>
<body class="bg-slate-950 text-slate-200 min-h-screen flex flex-col overflow-hidden">
    <!-- Header -->
    <header class="border-b border-slate-800/80 px-6 py-3 flex-shrink-0 z-10 bg-slate-950/80 backdrop-blur-md">
        <div class="flex items-center justify-between max-w-[1920px] mx-auto">
            <div class="flex items-center gap-3">
                <img src="/static/assets/logo.png" alt="NexusCore" class="w-9 h-9">
                <div>
                    <h1 class="text-lg font-semibold text-white tracking-tight leading-none">NexusCore</h1>
                    <p class="text-[10px] text-slate-500 font-medium tracking-[0.2em] uppercase mt-0.5">Agents · Connect · Create</p>
                </div>
            </div>
            <div class="flex items-center gap-3">
                <span class="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-500/10 text-emerald-400 text-[11px] font-medium border border-emerald-500/20">
                    <span class="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>Online
                </span>
                <span class="text-[11px] text-slate-600 font-mono">v0.1.0</span>
            </div>
        </div>
    </header>

    <!-- Main Layout -->
    <main class="flex-1 flex max-w-[1920px] mx-auto w-full p-4 gap-4 min-h-0">
        
        <!-- Left Panel: Controls -->
        <section class="w-[400px] flex-shrink-0 flex flex-col gap-4 overflow-y-auto pr-1">
            <!-- Stats -->
            <div class="grid grid-cols-3 gap-3">
                <div class="glass-panel rounded-xl p-4 text-center">
                    <p class="text-[10px] text-slate-500 uppercase tracking-wider mb-1">Crates</p>
                    <p class="text-xl font-bold text-white">7</p>
                </div>
                <div class="glass-panel rounded-xl p-4 text-center">
                    <p class="text-[10px] text-slate-500 uppercase tracking-wider mb-1">Tests</p>
                    <p class="text-xl font-bold text-emerald-400">11</p>
                </div>
                <div class="glass-panel rounded-xl p-4 text-center">
                    <p class="text-[10px] text-slate-500 uppercase tracking-wider mb-1">Agents</p>
                    <p class="text-xl font-bold text-blue-400">4</p>
                </div>
            </div>

            <!-- Actions -->
            <div class="glass-panel rounded-xl p-4 space-y-2">
                <p class="text-[10px] font-semibold text-slate-500 uppercase tracking-wider mb-3 px-1">Quick Actions</p>
                <button onclick="buildWorkspace()" class="w-full flex items-center gap-3 p-3 rounded-lg bg-slate-800/40 hover:bg-blue-600/15 border border-slate-700/40 hover:border-blue-500/40 transition-all text-left group">
                    <div class="w-8 h-8 rounded-md bg-blue-500/10 flex items-center justify-center group-hover:bg-blue-500/20"><i data-lucide="hammer" class="w-4 h-4 text-blue-400"></i></div>
                    <div><p class="text-sm font-medium text-slate-200">Build Workspace</p><p class="text-[10px] text-slate-500">Compile all crates</p></div>
                </button>
                <button onclick="runTests()" class="w-full flex items-center gap-3 p-3 rounded-lg bg-slate-800/40 hover:bg-emerald-600/15 border border-slate-700/40 hover:border-emerald-500/40 transition-all text-left group">
                    <div class="w-8 h-8 rounded-md bg-emerald-500/10 flex items-center justify-center group-hover:bg-emerald-500/20"><i data-lucide="flask-conical" class="w-4 h-4 text-emerald-400"></i></div>
                    <div><p class="text-sm font-medium text-slate-200">Run Tests</p><p class="text-[10px] text-slate-500">Execute test suite</p></div>
                </button>
                <button onclick="openDocs()" class="w-full flex items-center gap-3 p-3 rounded-lg bg-slate-800/40 hover:bg-purple-600/15 border border-slate-700/40 hover:border-purple-500/40 transition-all text-left group">
                    <div class="w-8 h-8 rounded-md bg-purple-500/10 flex items-center justify-center group-hover:bg-purple-500/20"><i data-lucide="book-open" class="w-4 h-4 text-purple-400"></i></div>
                    <div><p class="text-sm font-medium text-slate-200">Documentation</p><p class="text-[10px] text-slate-500">Open API docs</p></div>
                </button>
            </div>

            <!-- Logs -->
            <div class="glass-panel rounded-xl p-4 flex-1 flex flex-col min-h-[200px]">
                <div class="flex items-center justify-between mb-2">
                    <p class="text-[10px] font-semibold text-slate-500 uppercase tracking-wider">Output Log</p>
                    <button onclick="clearLogs()" class="text-[10px] text-slate-600 hover:text-slate-400">Clear</button>
                </div>
                <div id="build-logs" class="flex-1 overflow-y-auto font-mono text-[11px] space-y-0.5 text-slate-500">
                    <p class="italic text-slate-700">Ready...</p>
                </div>
            </div>
        </section>

        <!-- Right Panel: Agent Chat (Full Height) -->
        <section class="flex-1 flex flex-col glass-panel rounded-xl overflow-hidden min-w-0">
            <!-- Agent Selector Tabs -->
            <div class="flex items-center gap-1 p-3 border-b border-slate-700/40 bg-slate-900/30 overflow-x-auto">
                <button onclick="selectAgent('general')" class="agent-btn active flex items-center gap-2 px-4 py-2 rounded-lg border border-transparent hover:bg-slate-800/60 transition-all text-sm whitespace-nowrap" data-agent="general">
                    <i data-lucide="bot" class="w-4 h-4 text-cyan-400"></i>
                    <span class="font-medium">General</span>
                </button>
                <div class="w-px h-6 bg-slate-700/50 mx-1"></div>
                <button onclick="selectAgent('architect')" class="agent-btn flex items-center gap-2 px-4 py-2 rounded-lg border border-transparent hover:bg-slate-800/60 transition-all text-sm whitespace-nowrap" data-agent="architect">
                    <i data-lucide="compass" class="w-4 h-4 text-blue-400"></i>
                    <span class="font-medium">Architect</span>
                </button>
                <button onclick="selectAgent('coder')" class="agent-btn flex items-center gap-2 px-4 py-2 rounded-lg border border-transparent hover:bg-slate-800/60 transition-all text-sm whitespace-nowrap" data-agent="coder">
                    <i data-lucide="code" class="w-4 h-4 text-emerald-400"></i>
                    <span class="font-medium">Coder</span>
                </button>
                <button onclick="selectAgent('reviewer')" class="agent-btn flex items-center gap-2 px-4 py-2 rounded-lg border border-transparent hover:bg-slate-800/60 transition-all text-sm whitespace-nowrap" data-agent="reviewer">
                    <i data-lucide="search-check" class="w-4 h-4 text-amber-400"></i>
                    <span class="font-medium">Reviewer</span>
                </button>
                <button onclick="selectAgent('researcher')" class="agent-btn flex items-center gap-2 px-4 py-2 rounded-lg border border-transparent hover:bg-slate-800/60 transition-all text-sm whitespace-nowrap" data-agent="researcher">
                    <i data-lucide="book-open" class="w-4 h-4 text-purple-400"></i>
                    <span class="font-medium">Researcher</span>
                </button>
            </div>

            <!-- Active Agent Info Bar -->
            <div id="agent-info" class="px-5 py-2.5 bg-gradient-to-r from-cyan-500/5 to-transparent border-b border-slate-800/40 flex items-center gap-3">
                <div id="agent-icon" class="w-7 h-7 rounded-md bg-cyan-500/15 flex items-center justify-center">
                    <i data-lucide="bot" class="w-3.5 h-3.5 text-cyan-400"></i>
                </div>
                <div>
                    <p id="agent-name" class="text-sm font-semibold text-white">General Assistant</p>
                    <p id="agent-desc" class="text-[11px] text-slate-500">Multi-purpose AI assistant for NexusCore</p>
                </div>
            </div>

            <!-- Chat Area -->
            <div id="chat-history" class="flex-1 overflow-y-auto p-5 space-y-5">
                <div class="flex gap-3">
                    <div class="w-7 h-7 rounded-md bg-gradient-to-br from-cyan-500 to-blue-600 flex-shrink-0 flex items-center justify-center mt-0.5">
                        <i data-lucide="bot" class="w-3.5 h-3.5 text-white"></i>
                    </div>
                    <div class="chat-message flex-1">
                        <p class="text-[10px] text-slate-500 mb-1 font-medium">NexusCore AI</p>
                        <div class="text-slate-300 text-sm">Welcome! Select an agent above or chat with me directly. Each agent has specialized expertise.</div>
                    </div>
                </div>
            </div>

            <!-- Input -->
            <div class="p-4 border-t border-slate-700/40 bg-slate-900/40">
                <div class="flex gap-2">
                    <input type="text" id="chat-input" class="flex-1 bg-slate-800/80 text-white px-4 py-2.5 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/40 placeholder-slate-500 text-sm border border-slate-700/50" placeholder="Ask the selected agent..." onkeypress="if(event.key==='Enter')sendChat()">
                    <button onclick="sendChat()" class="px-5 py-2.5 bg-blue-600 hover:bg-blue-500 rounded-lg transition-colors font-medium text-sm flex items-center gap-2">
                        Send <i data-lucide="send" class="w-3.5 h-3.5"></i>
                    </button>
                </div>
            </div>
        </section>
    </main>

    <script>
        lucide.createIcons();
        marked.setOptions({ breaks: true, gfm: true });

        let currentAgent = 'general';
        const agentMeta = {
            general: { name: 'General Assistant', desc: 'Multi-purpose AI assistant for NexusCore', icon: 'bot', color: 'cyan' },
            architect: { name: 'Architect Agent', desc: 'System design, architecture & technology decisions', icon: 'compass', color: 'blue' },
            coder: { name: 'Coder Agent', desc: 'Clean, idiomatic Rust code generation', icon: 'code', color: 'emerald' },
            reviewer: { name: 'Reviewer Agent', desc: 'Code review, quality checks & best practices', icon: 'search-check', color: 'amber' },
            researcher: { name: 'Researcher Agent', desc: 'Crate research, comparisons & documentation', icon: 'book-open', color: 'purple' }
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
                history.innerHTML += `<div class="flex gap-3 flex-row-reverse">
                    <div class="w-7 h-7 rounded-md bg-slate-700 flex-shrink-0 flex items-center justify-center mt-0.5"><i data-lucide="user" class="w-3.5 h-3.5 text-slate-300"></i></div>
                    <div class="flex-1 text-right"><p class="text-[10px] text-slate-500 mb-1">You · ${time}</p>
                    <div class="inline-block bg-blue-600/15 text-blue-100 px-4 py-2 rounded-2xl rounded-tr-sm text-sm text-left">${content}</div></div></div>`;
            } else {
                const label = currentAgent === 'general' ? 'NexusCore AI' : meta.name;
                history.innerHTML += `<div class="flex gap-3">
                    <div class="w-7 h-7 rounded-md bg-gradient-to-br from-${meta.color}-500 to-${meta.color}-600 flex-shrink-0 flex items-center justify-center mt-0.5"><i data-lucide="${meta.icon}" class="w-3.5 h-3.5 text-white"></i></div>
                    <div class="chat-message flex-1"><p class="text-[10px] text-slate-500 mb-1 font-medium">${label} · ${time}</p>
                    <div class="text-slate-300 text-sm">${formatMessage(content)}</div></div></div>`;
            }
            history.scrollTop = history.scrollHeight;
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
            history.innerHTML += `<div id="${tid}" class="flex gap-3">
                <div class="w-7 h-7 rounded-md bg-${meta.color}-500/15 flex-shrink-0 flex items-center justify-center mt-0.5"><i data-lucide="${meta.icon}" class="w-3.5 h-3.5 text-${meta.color}-400"></i></div>
                <div class="flex-1"><p class="text-[10px] text-slate-500 mb-1 font-medium">${meta.name}</p>
                <div class="flex gap-1 text-slate-600 text-sm"><span class="animate-bounce">●</span><span class="animate-bounce" style="animation-delay:.1s">●</span><span class="animate-bounce" style="animation-delay:.2s">●</span></div></div></div>`;
            history.scrollTop = history.scrollHeight;
            
            try {
                let res;
                if (currentAgent === 'general') {
                    res = await axios.post('/api/chat', { message });
                    addMessage('ai', res.data.response);
                } else {
                    res = await axios.post('/api/agents/chat', { agent: currentAgent, message });
                    addMessage('ai', res.data.response);
                }
            } catch (e) {
                addMessage('ai', `⚠️ Error: ${e.response?.data || e.message}`);
            }
            document.getElementById(tid)?.remove();
        }

        function log(msg, type='info') {
            const el = document.getElementById('build-logs');
            const colors = { info: 'text-slate-500', success: 'text-emerald-400', error: 'text-red-400', warning: 'text-amber-400' };
            el.innerHTML += `<p class="${colors[type]}"><span class="text-slate-700">[${new Date().toLocaleTimeString()}]</span> ${msg}</p>`;
            el.scrollTop = el.scrollHeight;
        }
        function clearLogs() { document.getElementById('build-logs').innerHTML = '<p class="italic text-slate-700">Cleared.</p>'; }

        async function buildWorkspace() { log('Building...', 'info'); try { await axios.get('/api/build'); log('Build started', 'success'); } catch(e) { log('Build failed: '+e.message, 'error'); } }
        async function runTests() { log('Testing...', 'info'); try { await axios.get('/api/test'); log('Tests started', 'success'); } catch(e) { log('Test failed: '+e.message, 'error'); } }
        async function openDocs() { log('Opening docs...', 'info'); try { await axios.get('/api/docs'); log('Docs opened', 'success'); } catch(e) { log('Failed: '+e.message, 'error'); } }

        function startLogsStream() {
            const ws = new WebSocket('ws://localhost:3000/api/logs/ws');
            ws.onmessage = (e) => { e.data.split('\n').filter(l=>l.trim()).forEach(l => { 
                if(l.includes('error')) log(l,'error'); else if(l.includes('Finished')) log(l,'success'); else if(l.includes('warning')) log(l,'warning'); else if(l.trim()) log(l,'info');
            }); };
            ws.onclose = () => setTimeout(startLogsStream, 5000);
            ws.onerror = () => {};
        }

        document.addEventListener('DOMContentLoaded', () => { startLogsStream(); document.getElementById('chat-input').focus(); });
    </script>
</body>
</html>
HTMLEOF

# 4. Build
echo "🔨 Building agent-integrated dashboard..."
cargo build -p dashboard-server

echo ""
echo "========================================="
echo " ✅ Phase 15: Agent UI Complete!"
echo "========================================="
echo ""
echo " 🤖 Agent Tabs:"
echo "   • General    - Multi-purpose assistant"
echo "   • Architect  - System design expert"
echo "   • Coder      - Rust code generator"
echo "   • Reviewer   - Code quality checker"
echo "   • Researcher - Tech researcher"
echo ""
echo " 🚀 Restart: cargo run -p dashboard-server"
echo " 🌐 Open: http://localhost:3000"