#!/usr/bin/env bash
set -e

echo "🎨 Initializing Phase 13: Professional Dashboard Redesign..."

# Update index.html with professional minimalist design
cat > crates/dashboard/static/index.html <<'EOF'
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
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; }
        .code-block { 
            font-family: 'JetBrains Mono', monospace; 
            background: #1a1a2e;
            border-left: 3px solid #3b82f6;
        }
        .chat-message pre {
            background: #0f172a;
            border-radius: 8px;
            padding: 1rem;
            overflow-x: auto;
            margin: 0.5rem 0;
        }
        .chat-message code {
            font-family: 'JetBrains Mono', monospace;
            font-size: 0.875rem;
        }
        .chat-message p { margin-bottom: 0.75rem; line-height: 1.6; }
        .chat-message ul, .chat-message ol { margin-left: 1.5rem; margin-bottom: 0.75rem; }
        .glass-panel {
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(12px);
            border: 1px solid rgba(148, 163, 184, 0.1);
        }
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: #1e293b; }
        ::-webkit-scrollbar-thumb { background: #475569; border-radius: 3px; }
        ::-webkit-scrollbar-thumb:hover { background: #64748b; }
    </style>
</head>
<body class="bg-slate-950 text-slate-200 min-h-screen flex flex-col">
    <!-- Minimal Header -->
    <header class="border-b border-slate-800 px-6 py-4">
        <div class="flex items-center justify-between max-w-[1800px] mx-auto">
            <div class="flex items-center gap-4">
                <img src="/static/assets/logo.png" alt="NexusCore" class="w-10 h-10">
                <div>
                    <h1 class="text-xl font-semibold text-white tracking-tight">NexusCore</h1>
                    <p class="text-xs text-slate-500 font-medium tracking-widest uppercase">Agents · Connect · Create</p>
                </div>
            </div>
            <div class="flex items-center gap-3">
                <span class="flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-500/10 text-emerald-400 text-xs font-medium border border-emerald-500/20">
                    <span class="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                    Online
                </span>
                <span class="text-xs text-slate-500 font-mono">v0.1.0</span>
            </div>
        </div>
    </header>

    <!-- Main Content: 50/50 Split -->
    <main class="flex-1 flex max-w-[1800px] mx-auto w-full p-6 gap-6">
        
        <!-- Left Panel: Dashboard Controls (50%) -->
        <section class="flex-1 flex flex-col gap-6 min-w-0">
            <!-- Stats Row -->
            <div class="grid grid-cols-3 gap-4">
                <div class="glass-panel rounded-xl p-5">
                    <div class="flex items-center justify-between mb-2">
                        <span class="text-xs text-slate-500 font-medium uppercase tracking-wider">Crates</span>
                        <i data-lucide="package" class="w-4 h-4 text-blue-400"></i>
                    </div>
                    <p class="text-2xl font-bold text-white">6</p>
                </div>
                <div class="glass-panel rounded-xl p-5">
                    <div class="flex items-center justify-between mb-2">
                        <span class="text-xs text-slate-500 font-medium uppercase tracking-wider">Tests</span>
                        <i data-lucide="circle-check" class="w-4 h-4 text-emerald-400"></i>
                    </div>
                    <p class="text-2xl font-bold text-white">11</p>
                </div>
                <div class="glass-panel rounded-xl p-5">
                    <div class="flex items-center justify-between mb-2">
                        <span class="text-xs text-slate-500 font-medium uppercase tracking-wider">Runtime</span>
                        <i data-lucide="zap" class="w-4 h-4 text-amber-400"></i>
                    </div>
                    <p class="text-2xl font-bold text-white">Tokio</p>
                </div>
            </div>

            <!-- Quick Actions -->
            <div class="glass-panel rounded-xl p-6 flex-1">
                <h2 class="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4">Quick Actions</h2>
                <div class="grid grid-cols-1 gap-3">
                    <button onclick="buildWorkspace()" class="group flex items-center gap-4 p-4 rounded-lg bg-slate-800/50 hover:bg-blue-600/20 border border-slate-700/50 hover:border-blue-500/50 transition-all text-left">
                        <div class="w-10 h-10 rounded-lg bg-blue-500/10 flex items-center justify-center group-hover:bg-blue-500/20 transition-colors">
                            <i data-lucide="hammer" class="w-5 h-5 text-blue-400"></i>
                        </div>
                        <div>
                            <p class="font-medium text-white">Build Workspace</p>
                            <p class="text-xs text-slate-500">Compile all crates</p>
                        </div>
                    </button>
                    <button onclick="runTests()" class="group flex items-center gap-4 p-4 rounded-lg bg-slate-800/50 hover:bg-emerald-600/20 border border-slate-700/50 hover:border-emerald-500/50 transition-all text-left">
                        <div class="w-10 h-10 rounded-lg bg-emerald-500/10 flex items-center justify-center group-hover:bg-emerald-500/20 transition-colors">
                            <i data-lucide="flask-conical" class="w-5 h-5 text-emerald-400"></i>
                        </div>
                        <div>
                            <p class="font-medium text-white">Run Tests</p>
                            <p class="text-xs text-slate-500">Execute test suite</p>
                        </div>
                    </button>
                    <button onclick="openDocs()" class="group flex items-center gap-4 p-4 rounded-lg bg-slate-800/50 hover:bg-purple-600/20 border border-slate-700/50 hover:border-purple-500/50 transition-all text-left">
                        <div class="w-10 h-10 rounded-lg bg-purple-500/10 flex items-center justify-center group-hover:bg-purple-500/20 transition-colors">
                            <i data-lucide="book-open" class="w-5 h-5 text-purple-400"></i>
                        </div>
                        <div>
                            <p class="font-medium text-white">Documentation</p>
                            <p class="text-xs text-slate-500">Open API docs</p>
                        </div>
                    </button>
                </div>
            </div>

            <!-- Build Logs -->
            <div class="glass-panel rounded-xl p-6 h-48 flex flex-col">
                <div class="flex items-center justify-between mb-3">
                    <h2 class="text-sm font-semibold text-slate-400 uppercase tracking-wider">Output Log</h2>
                    <button onclick="clearLogs()" class="text-xs text-slate-500 hover:text-slate-300 transition-colors">Clear</button>
                </div>
                <div id="build-logs" class="flex-1 overflow-y-auto font-mono text-xs space-y-1 text-slate-400">
                    <p class="text-slate-600 italic">Ready for commands...</p>
                </div>
            </div>
        </section>

        <!-- Right Panel: AI Chat (50%) -->
        <section class="flex-1 flex flex-col glass-panel rounded-xl overflow-hidden min-w-0">
            <!-- Chat Header -->
            <div class="px-6 py-4 border-b border-slate-700/50 flex items-center justify-between">
                <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-cyan-500 to-blue-600 flex items-center justify-center">
                        <i data-lucide="bot" class="w-4 h-4 text-white"></i>
                    </div>
                    <div>
                        <h2 class="font-semibold text-white">NexusCore AI</h2>
                        <p class="text-xs text-slate-500">Powered by Gemma</p>
                    </div>
                </div>
                <button onclick="clearChat()" class="p-2 rounded-lg hover:bg-slate-700/50 transition-colors text-slate-500 hover:text-slate-300">
                    <i data-lucide="trash-2" class="w-4 h-4"></i>
                </button>
            </div>

            <!-- Chat Messages Area -->
            <div id="chat-history" class="flex-1 overflow-y-auto p-6 space-y-6">
                <!-- Welcome Message -->
                <div class="flex gap-3">
                    <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-cyan-500 to-blue-600 flex-shrink-0 flex items-center justify-center mt-1">
                        <i data-lucide="bot" class="w-4 h-4 text-white"></i>
                    </div>
                    <div class="chat-message flex-1">
                        <p class="text-xs text-slate-500 mb-1 font-medium">NexusCore AI</p>
                        <div class="text-slate-300 text-sm leading-relaxed">
                            Hello! I'm your NexusCore assistant. I can help you with:
                            <ul class="mt-2 space-y-1 text-slate-400">
                                <li>• Rust code generation & review</li>
                                <li>• Workspace management</li>
                                <li>• Debugging & optimization</li>
                                <li>• Architecture guidance</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Chat Input -->
            <div class="p-4 border-t border-slate-700/50 bg-slate-900/50">
                <div class="flex gap-3">
                    <input 
                        type="text" 
                        id="chat-input" 
                        class="flex-1 bg-slate-800 text-white px-4 py-3 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500/50 placeholder-slate-500 text-sm"
                        placeholder="Ask me anything about NexusCore..."
                        onkeypress="if(event.key === 'Enter') sendChat()"
                    >
                    <button 
                        onclick="sendChat()" 
                        class="px-5 py-3 bg-blue-600 hover:bg-blue-500 rounded-lg transition-colors flex items-center gap-2 font-medium text-sm"
                    >
                        <span>Send</span>
                        <i data-lucide="send" class="w-4 h-4"></i>
                    </button>
                </div>
                <p class="text-xs text-slate-600 mt-2 text-center">AI responses may include code blocks with syntax highlighting</p>
            </div>
        </section>
    </main>

    <script>
        lucide.createIcons();
        
        // Configure marked for code highlighting
        marked.setOptions({
            breaks: true,
            gfm: true
        });

        function formatMessage(text) {
            // Parse markdown and format code blocks
            let html = marked.parse(text);
            
            // Add special styling to code blocks
            html = html.replace(/<pre><code class="language-(\w+)">/g, '<pre class="code-block"><code class="language-$1">');
            html = html.replace(/<pre><code>/g, '<pre class="code-block"><code>');
            
            return html;
        }

        function addMessage(role, content, isUser = false) {
            const history = document.getElementById('chat-history');
            const timestamp = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            
            if (isUser) {
                history.innerHTML += `
                    <div class="flex gap-3 flex-row-reverse">
                        <div class="w-8 h-8 rounded-lg bg-slate-700 flex-shrink-0 flex items-center justify-center mt-1">
                            <i data-lucide="user" class="w-4 h-4 text-slate-300"></i>
                        </div>
                        <div class="chat-message flex-1 text-right">
                            <p class="text-xs text-slate-500 mb-1 font-medium">You · ${timestamp}</p>
                            <div class="inline-block bg-blue-600/20 text-blue-100 px-4 py-2 rounded-2xl rounded-tr-sm text-sm">
                                ${content}
                            </div>
                        </div>
                    </div>
                `;
            } else {
                history.innerHTML += `
                    <div class="flex gap-3">
                        <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-cyan-500 to-blue-600 flex-shrink-0 flex items-center justify-center mt-1">
                            <i data-lucide="bot" class="w-4 h-4 text-white"></i>
                        </div>
                        <div class="chat-message flex-1">
                            <p class="text-xs text-slate-500 mb-1 font-medium">NexusCore AI · ${timestamp}</p>
                            <div class="text-slate-300 text-sm leading-relaxed">
                                ${formatMessage(content)}
                            </div>
                        </div>
                    </div>
                `;
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
            
            // Show typing indicator
            const history = document.getElementById('chat-history');
            const typingId = 'typing-' + Date.now();
            history.innerHTML += `
                <div id="${typingId}" class="flex gap-3">
                    <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-cyan-500 to-blue-600 flex-shrink-0 flex items-center justify-center mt-1">
                        <i data-lucide="bot" class="w-4 h-4 text-white"></i>
                    </div>
                    <div class="flex-1">
                        <p class="text-xs text-slate-500 mb-1 font-medium">NexusCore AI</p>
                        <div class="flex gap-1 items-center text-slate-500 text-sm">
                            <span class="animate-bounce">●</span>
                            <span class="animate-bounce" style="animation-delay: 0.1s">●</span>
                            <span class="animate-bounce" style="animation-delay: 0.2s">●</span>
                        </div>
                    </div>
                </div>
            `;
            history.scrollTop = history.scrollHeight;
            
            try {
                const response = await axios.post('/api/chat', { message });
                
                // Remove typing indicator
                document.getElementById(typingId)?.remove();
                
                addMessage('ai', response.data.response);
            } catch (error) {
                document.getElementById(typingId)?.remove();
                addMessage('ai', `⚠️ Error: ${error.message}. Make sure Ollama is running.`);
            }
        }

        function log(message, type = 'info') {
            const logsDiv = document.getElementById('build-logs');
            const colors = {
                info: 'text-slate-400',
                success: 'text-emerald-400',
                error: 'text-red-400',
                warning: 'text-amber-400'
            };
            const time = new Date().toLocaleTimeString();
            logsDiv.innerHTML += `<p class="${colors[type]}"><span class="text-slate-600">[${time}]</span> ${message}</p>`;
            logsDiv.scrollTop = logsDiv.scrollHeight;
        }

        function clearLogs() {
            document.getElementById('build-logs').innerHTML = '<p class="text-slate-600 italic">Logs cleared.</p>';
        }

        function clearChat() {
            document.getElementById('chat-history').innerHTML = '';
            addMessage('ai', 'Chat cleared. How can I help you?');
        }

        async function buildWorkspace() {
            log('Starting workspace build...', 'info');
            try {
                await axios.get('/api/build');
                log('Build process initiated successfully', 'success');
            } catch (error) {
                log(`Build failed: ${error.message}`, 'error');
            }
        }

        async function runTests() {
            log('Running test suite...', 'info');
            try {
                await axios.get('/api/test');
                log('Test execution started', 'success');
            } catch (error) {
                log(`Tests failed: ${error.message}`, 'error');
            }
        }

        async function openDocs() {
            log('Opening documentation...', 'info');
            try {
                await axios.get('/api/docs');
                log('Documentation opened in browser', 'success');
            } catch (error) {
                log(`Failed to open docs: ${error.message}`, 'error');
            }
        }

        // WebSocket for real-time logs
        function startLogsStream() {
            const ws = new WebSocket('ws://localhost:3000/api/logs/ws');
            
            ws.onmessage = (event) => {
                const lines = event.data.split('\n').filter(l => l.trim());
                lines.forEach(line => {
                    if (line.includes('error') || line.includes('Error')) {
                        log(line, 'error');
                    } else if (line.includes('Finished') || line.includes('passed')) {
                        log(line, 'success');
                    } else if (line.includes('warning') || line.includes('Warning')) {
                        log(line, 'warning');
                    } else if (line.trim()) {
                        log(line, 'info');
                    }
                });
            };
            
            ws.onclose = () => setTimeout(startLogsStream, 5000);
            ws.onerror = () => {};
        }

        document.addEventListener('DOMContentLoaded', () => {
            startLogsStream();
            document.getElementById('chat-input').focus();
        });
    </script>
</body>
</html>
EOF

echo ""
echo "========================================="
echo " ✅ Dashboard Redesigned!"
echo "========================================="
echo ""
echo " 🎨 New Features:"
echo "   • 50/50 split layout (Controls | Chat)"
echo "   • Professional minimalist design"
echo "   • Code-aware chat responses"
echo "   • Syntax highlighted code blocks"
echo "   • Glass morphism panels"
echo "   • Real-time log streaming"
echo ""
echo " 🚀 Restart the dashboard:"
echo "    cargo run -p dashboard-server"
echo ""
echo " 🌐 Then refresh: http://localhost:3000"