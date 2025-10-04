const express = require('express');
const axios = require('axios');
const WebSocket = require('ws');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const cron = require('node-cron');
const si = require('systeminformation');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Service configuration
const services = {
    openwebui: {
        name: 'Open WebUI',
        url: 'http://open-webui:8080',
        healthEndpoint: '/health',
        icon: '🤖'
    },
    ollama: {
        name: 'Ollama',
        url: 'http://ollama:11434',
        healthEndpoint: '/api/tags',
        icon: '🧠'
    },
    qdrant: {
        name: 'Qdrant',
        url: 'http://qdrant:6333',
        healthEndpoint: '/health',
        icon: '🔍'
    },
    langfuse: {
        name: 'Langfuse',
        url: 'http://langfuse:3000',
        healthEndpoint: '/api/public/health',
        icon: '📊'
    },
    pipelines: {
        name: 'Pipelines',
        url: 'http://pipelines:9099',
        healthEndpoint: '/health',
        icon: '🔧'
    }
};

// Global state
let systemMetrics = {};
let serviceStatus = {};
let lastUpdate = new Date();

// WebSocket server for real-time updates
const wss = new WebSocket.Server({ port: 8081 });

// Broadcast to all connected clients
function broadcast(data) {
    wss.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify(data));
        }
    });
}

// Check service health
async function checkServiceHealth(serviceName, config) {
    try {
        const response = await axios.get(
            `${config.url}${config.healthEndpoint}`,
            { timeout: 5000 }
        );
        
        return {
            name: serviceName,
            status: 'healthy',
            responseTime: response.headers['x-response-time'] || 'N/A',
            lastCheck: new Date().toISOString(),
            icon: config.icon
        };
    } catch (error) {
        return {
            name: serviceName,
            status: 'unhealthy',
            error: error.message,
            lastCheck: new Date().toISOString(),
            icon: config.icon
        };
    }
}

// Get system metrics
async function getSystemMetrics() {
    try {
        const [cpu, memory, disk, network] = await Promise.all([
            si.currentLoad(),
            si.mem(),
            si.fsSize(),
            si.networkStats()
        ]);

        return {
            cpu: {
                usage: Math.round(cpu.currentLoad),
                cores: cpu.cpus?.length || 0
            },
            memory: {
                total: Math.round(memory.total / 1024 / 1024 / 1024), // GB
                used: Math.round(memory.used / 1024 / 1024 / 1024), // GB
                usage: Math.round((memory.used / memory.total) * 100)
            },
            disk: disk.map(d => ({
                mount: d.mount,
                size: Math.round(d.size / 1024 / 1024 / 1024), // GB
                used: Math.round(d.used / 1024 / 1024 / 1024), // GB
                usage: Math.round(d.use)
            })),
            network: network.map(n => ({
                iface: n.iface,
                rx: Math.round(n.rx_bytes / 1024 / 1024), // MB
                tx: Math.round(n.tx_bytes / 1024 / 1024)  // MB
            })),
            timestamp: new Date().toISOString()
        };
    } catch (error) {
        console.error('Error getting system metrics:', error);
        return null;
    }
}

// Get Ollama models
async function getOllamaModels() {
    try {
        const response = await axios.get('http://ollama:11434/api/tags', {
            timeout: 5000
        });
        return response.data.models || [];
    } catch (error) {
        console.error('Error getting Ollama models:', error);
        return [];
    }
}

// Get pipeline status
async function getPipelineStatus() {
    try {
        const response = await axios.get('http://pipelines:9099/pipelines', {
            headers: { 'Authorization': 'Bearer 0p3n-w3bu!' },
            timeout: 5000
        });
        return response.data.data || [];
    } catch (error) {
        console.error('Error getting pipeline status:', error);
        return [];
    }
}

// Update all metrics
async function updateMetrics() {
    console.log('Updating metrics...');
    
    // Check service health
    const healthChecks = Object.entries(services).map(([name, config]) =>
        checkServiceHealth(name, config)
    );
    
    const healthResults = await Promise.all(healthChecks);
    serviceStatus = healthResults.reduce((acc, result) => {
        acc[result.name] = result;
        return acc;
    }, {});
    
    // Get system metrics
    systemMetrics = await getSystemMetrics();
    
    // Get additional data
    const [models, pipelines] = await Promise.all([
        getOllamaModels(),
        getPipelineStatus()
    ]);
    
    const updateData = {
        type: 'update',
        timestamp: new Date().toISOString(),
        services: serviceStatus,
        system: systemMetrics,
        models: models,
        pipelines: pipelines
    };
    
    // Broadcast to WebSocket clients
    broadcast(updateData);
    
    lastUpdate = new Date();
    console.log('Metrics updated successfully');
}

// Schedule metric updates every 30 seconds
cron.schedule('*/30 * * * * *', updateMetrics);

// Initial metrics update
updateMetrics();

// Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

app.get('/api/status', (req, res) => {
    res.json({
        services: serviceStatus,
        system: systemMetrics,
        lastUpdate: lastUpdate.toISOString()
    });
});

app.get('/api/services', (req, res) => {
    res.json(serviceStatus);
});

app.get('/api/system', (req, res) => {
    res.json(systemMetrics);
});

app.get('/api/models', async (req, res) => {
    try {
        const models = await getOllamaModels();
        res.json(models);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/pipelines', async (req, res) => {
    try {
        const pipelines = await getPipelineStatus();
        res.json(pipelines);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// WebSocket connection handling
wss.on('connection', (ws) => {
    console.log('New WebSocket connection');
    
    // Send current data to new client
    ws.send(JSON.stringify({
        type: 'initial',
        services: serviceStatus,
        system: systemMetrics,
        timestamp: new Date().toISOString()
    }));
    
    ws.on('close', () => {
        console.log('WebSocket connection closed');
    });
    
    ws.on('error', (error) => {
        console.error('WebSocket error:', error);
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`NumberOne OWU Dashboard running on port ${PORT}`);
    console.log(`WebSocket server running on port 8081`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('Received SIGTERM, shutting down gracefully');
    wss.close(() => {
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('Received SIGINT, shutting down gracefully');
    wss.close(() => {
        process.exit(0);
    });
});
