# BBR Log Server

A real-time log visualization server with a Matrix-style rain effect. This application receives log entries via HTTP POST requests and broadcasts them to connected WebSocket clients for real-time visualization.

## Features

- **Real-time Log Streaming**: WebSocket-based real-time log broadcasting
- **Matrix-style Visualization**: Animated log entries with falling rain effect
- **RESTful API**: Simple HTTP POST endpoint for log ingestion
- **Log Level Validation**: Supports standard log levels (emergency, alert, critical, error, warning, notice, info, debug)
- **Live Statistics**: Real-time server statistics display
- **Docker Support**: Containerized deployment ready

## Quick Start

### Using Docker (Recommended)

1. **Build the Docker image:**
   ```bash
   docker build -t bbr-log-server .
   ```

2. **Run the container:**
   ```bash
   # Using default port 2069
   docker run -p 2069:2069 bbr-log-server
   
   # Using custom port
   docker run -p 8080:8080 -e PORT=8080 bbr-log-server
   ```

3. **Access the application:**
   - Open your browser to `http://your-domain.com:2069`
   - The web interface will display real-time logs with Matrix-style animation

### Manual Installation

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Start the server:**
   ```bash
   # Using default port 2069
   npm start
   
   # Using custom port
   PORT=8080 npm start
   ```

3. **Access the application:**
   - Open your browser to `http://your-domain.com:2069`

## API Usage

### Sending Log Entries

Send log entries to the server using HTTP POST requests:

```bash
curl -X POST http://your-domain.com:2069/logs \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Application started successfully",
    "level": "info",
    "timestamp": "2024-01-15T10:30:00Z",
    "source": "main.js"
  }'
```

### Required Fields

- `message` (string): The log message content
- `level` (string): Log level (emergency, alert, critical, error, warning, notice, info, debug)

### Optional Fields

- `timestamp` (string): ISO 8601 timestamp
- `source` (string): Source of the log entry
- `metadata` (object): Additional metadata

### Example Log Entries

```json
{
  "message": "Database connection established",
  "level": "info",
  "timestamp": "2024-01-15T10:30:00Z",
  "source": "database.js"
}
```

```json
{
  "message": "Critical error in payment processing",
  "level": "critical",
  "timestamp": "2024-01-15T10:31:15Z",
  "source": "payment.js",
  "metadata": {
    "userId": "12345",
    "transactionId": "tx_abc123"
  }
}
```

## Configuration

### Environment Variables

- `PORT`: Server port (default: 2069)

### Domain and DNS Configuration

Before deploying, you'll need to set up your domain and DNS:

1. **Purchase a domain** from a domain registrar (e.g., Namecheap, GoDaddy, Cloudflare)
2. **Point your domain** to your server's IP address:
   - Create an A record: `your-domain.com` → `YOUR_SERVER_IP`
   - Optionally create a CNAME for www: `www.your-domain.com` → `your-domain.com`
3. **Update the configuration** below with your actual domain name

### Nginx Configuration

For production deployment with Nginx as a reverse proxy:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    
    # Serve static files from public_html
    location / {
        root /path/to/your/log_visualizer/public_html;
        try_files $uri $uri/ /index.html;
    }
    
    # Proxy API requests to the Node.js server
    location /logs {
        proxy_pass http://127.0.0.1:2069;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Proxy WebSocket connections
    location / {
        proxy_pass http://127.0.0.1:2069;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### SSL/HTTPS Setup (Recommended)

For production, enable HTTPS using Let's Encrypt:

```bash
# Install certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Auto-renewal (already configured by certbot)
sudo certbot renew --dry-run
```

## Development

### Project Structure

```
log_visualizer/
├── server.js              # Main server application
├── package.json           # Node.js dependencies and scripts
├── Dockerfile            # Docker configuration
├── README.md             # This file
├── .gitignore            # Git ignore rules
└── public_html/          # Static web files
    ├── index.html        # Main web interface
    ├── poc.html          # Proof of concept page
    └── assets/
        ├── script.js     # Client-side JavaScript
        └── styles.css    # CSS styles
```

### Testing

Use the included test script to generate sample log entries:

```bash
chmod +x test_logs.sh
./test_logs.sh
```

This will send various log entries to the server for testing the visualization.

## License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**. This is a copyleft license that requires anyone who uses, modifies, or distributes this software to also share their modifications under the same license.

### Key Points:
- **Free to use**: You can use this software for any purpose
- **Share and share alike**: Any modifications must be shared under the same license
- **Network use**: Even if you host this as a service, you must share your modifications
- **Source code**: You must provide access to the source code when distributing

### Full License Text:
See the [LICENSE](LICENSE) file for the complete license text.

### Why AGPL-3.0?
This license ensures that improvements to the log visualizer remain open and available to the community, even when used in cloud environments or as a hosted service.

## Contributing

We welcome contributions! Please see our [CONTRIBUTING.md](CONTRIBUTING.md) file for detailed guidelines.

### Quick Start:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

### Important:
By contributing to this project, you agree that your contributions will be licensed under the same AGPL-3.0 license.

## Support

For issues and questions, please open an issue on the project repository.
