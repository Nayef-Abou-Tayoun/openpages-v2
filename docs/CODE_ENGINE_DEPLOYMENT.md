# IBM Code Engine Deployment Guide

This guide provides step-by-step instructions for deploying the OpenPages MCP Server to IBM Code Engine.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Deployment Options](#deployment-options)
3. [Quick Start](#quick-start)
4. [Detailed Deployment Steps](#detailed-deployment-steps)
5. [Configuration](#configuration)
6. [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
7. [Scaling and Performance](#scaling-and-performance)

---

## Prerequisites

### Required Tools
- IBM Cloud CLI: [Install Guide](https://cloud.ibm.com/docs/cli?topic=cli-getting-started)
- Code Engine plugin: `ibmcloud plugin install code-engine`
- Docker (for local testing): [Install Docker](https://docs.docker.com/get-docker/)

### IBM Cloud Account
- Active IBM Cloud account
- Access to IBM Code Engine service
- Appropriate IAM permissions

### OpenPages Instance
- OpenPages instance URL
- Valid credentials (username/password or API key)
- REST API v2 enabled

---

## Deployment Options

### Option 1: Deploy from Container Registry (Recommended)
Deploy using a pre-built Docker image from a container registry.

### Option 2: Deploy from Source Code
Let Code Engine build the container image from your source code.

### Option 3: Deploy from Local Docker Image
Build locally and push to IBM Container Registry.

---

## Quick Start

### 1. Login to IBM Cloud
```bash
# Login to IBM Cloud
ibmcloud login

# Target your resource group
ibmcloud target -g <your-resource-group>

# Select region (e.g., us-south, eu-de, jp-tok)
ibmcloud target -r us-south
```

### 2. Create Code Engine Project
```bash
# Create a new project
ibmcloud ce project create --name openpages-mcp-server

# Or select existing project
ibmcloud ce project select --name openpages-mcp-server
```

### 3. Deploy the Application

**Option A: From Docker Hub (if image is public)**
```bash
ibmcloud ce application create \
  --name openpages-mcp-server \
  --image docker.io/yourusername/openpages-mcp-server:latest \
  --port 8000 \
  --min-scale 1 \
  --max-scale 5 \
  --cpu 1 \
  --memory 2G \
  --env-from-configmap openpages-config \
  --env-from-secret openpages-credentials
```

**Option B: From IBM Container Registry**
```bash
# Build and push to IBM Container Registry
docker build -t us.icr.io/<namespace>/openpages-mcp-server:latest .
docker push us.icr.io/<namespace>/openpages-mcp-server:latest

# Deploy
ibmcloud ce application create \
  --name openpages-mcp-server \
  --image us.icr.io/<namespace>/openpages-mcp-server:latest \
  --registry-secret icr-secret \
  --port 8000 \
  --min-scale 1 \
  --max-scale 5 \
  --cpu 1 \
  --memory 2G \
  --env-from-configmap openpages-config \
  --env-from-secret openpages-credentials
```

**Option C: From Source Code**
```bash
# Deploy directly from source (Code Engine builds the image)
ibmcloud ce application create \
  --name openpages-mcp-server \
  --build-source . \
  --port 8000 \
  --min-scale 1 \
  --max-scale 5 \
  --cpu 1 \
  --memory 2G \
  --env-from-configmap openpages-config \
  --env-from-secret openpages-credentials
```

---

## Detailed Deployment Steps

### Step 1: Prepare Configuration

#### Create ConfigMap for Non-Sensitive Settings
```bash
ibmcloud ce configmap create --name openpages-config \
  --from-literal SERVER_MODE=remote \
  --from-literal DEBUG=False \
  --from-literal SSL_VERIFY=True \
  --from-literal LOG_LEVEL=INFO \
  --from-literal PORT=8000 \
  --from-literal HOST=0.0.0.0 \
  --from-literal OBSERVABILITY_ENABLED=True \
  --from-literal METRICS_ENABLED=True \
  --from-literal TRACING_ENABLED=False
```

#### Create Secret for Sensitive Credentials

**For Basic Authentication (On-Premises):**
```bash
ibmcloud ce secret create --name openpages-credentials \
  --from-literal OPENPAGES_BASE_URL=http://your-openpages-server:port/openpages/ \
  --from-literal OPENPAGES_AUTHENTICATION_TYPE=basic \
  --from-literal OPENPAGES_USERNAME=your_username \
  --from-literal OPENPAGES_PASSWORD=your_password
```

**For Bearer Authentication (IBM Cloud SaaS):**
```bash
ibmcloud ce secret create --name openpages-credentials \
  --from-literal OPENPAGES_BASE_URL=https://your-tenant.openpages.ibmcloud.com \
  --from-literal OPENPAGES_AUTHENTICATION_TYPE=bearer \
  --from-literal OPENPAGES_APIKEY=your_ibm_cloud_api_key \
  --from-literal OPENPAGES_AUTHENTICATION_URL=https://iam.cloud.ibm.com/identity/token
```

**For Bearer Authentication (MCSP SaaS):**
```bash
ibmcloud ce secret create --name openpages-credentials \
  --from-literal OPENPAGES_BASE_URL=https://your-tenant.openpages.saas.ibm.com \
  --from-literal OPENPAGES_AUTHENTICATION_TYPE=bearer \
  --from-literal OPENPAGES_APIKEY=base64_encoded_client_id:client_secret \
  --from-literal OPENPAGES_AUTHENTICATION_URL=https://account-iam.platform.saas.ibm.com/api/2.0/services/{service_id}/apikeys/token
```

### Step 2: Build and Push Docker Image (if not using source deployment)

#### Option A: Using IBM Container Registry
```bash
# Login to IBM Container Registry
ibmcloud cr login

# Create namespace (if not exists)
ibmcloud cr namespace-add <your-namespace>

# Build image
docker build -t us.icr.io/<your-namespace>/openpages-mcp-server:latest .

# Push image
docker push us.icr.io/<your-namespace>/openpages-mcp-server:latest

# Create registry secret in Code Engine
ibmcloud ce registry create --name icr-secret \
  --server us.icr.io \
  --username iamapikey \
  --password <your-ibm-cloud-api-key>
```

#### Option B: Using Docker Hub
```bash
# Login to Docker Hub
docker login

# Build and tag image
docker build -t yourusername/openpages-mcp-server:latest .

# Push image
docker push yourusername/openpages-mcp-server:latest

# If private, create registry secret
ibmcloud ce registry create --name dockerhub-secret \
  --server https://index.docker.io/v1/ \
  --username <your-dockerhub-username> \
  --password <your-dockerhub-password>
```

### Step 3: Deploy Application

#### Basic Deployment
```bash
ibmcloud ce application create \
  --name openpages-mcp-server \
  --image us.icr.io/<namespace>/openpages-mcp-server:latest \
  --registry-secret icr-secret \
  --port 8000 \
  --min-scale 1 \
  --max-scale 5 \
  --cpu 1 \
  --memory 2G \
  --env-from-configmap openpages-config \
  --env-from-secret openpages-credentials
```

#### Advanced Deployment with Custom Settings
```bash
ibmcloud ce application create \
  --name openpages-mcp-server \
  --image us.icr.io/<namespace>/openpages-mcp-server:latest \
  --registry-secret icr-secret \
  --port 8000 \
  --min-scale 1 \
  --max-scale 10 \
  --cpu 2 \
  --memory 4G \
  --concurrency 100 \
  --concurrency-target 80 \
  --request-timeout 300 \
  --env-from-configmap openpages-config \
  --env-from-secret openpages-credentials \
  --probe-live type=http,path=/health/live,port=8000,interval=30,timeout=10,failure-threshold=3 \
  --probe-ready type=http,path=/health/ready,port=8000,interval=10,timeout=5,failure-threshold=3
```

### Step 4: Verify Deployment

```bash
# Check application status
ibmcloud ce application get --name openpages-mcp-server

# Get application URL
ibmcloud ce application get --name openpages-mcp-server --output url

# Test health endpoint
curl $(ibmcloud ce application get --name openpages-mcp-server --output url)/health

# View logs
ibmcloud ce application logs --name openpages-mcp-server

# Follow logs in real-time
ibmcloud ce application logs --name openpages-mcp-server --follow
```

---

## Configuration

### Environment Variables

#### Required Variables (Set via Secret)
- `OPENPAGES_BASE_URL`: OpenPages instance URL
- `OPENPAGES_AUTHENTICATION_TYPE`: Authentication type (basic, bearer, form)
- `OPENPAGES_USERNAME`: Username (for basic/form auth)
- `OPENPAGES_PASSWORD`: Password (for basic/form auth)
- `OPENPAGES_APIKEY`: API key (for bearer auth)
- `OPENPAGES_AUTHENTICATION_URL`: Token URL (for bearer auth)

#### Optional Variables (Set via ConfigMap)
- `SERVER_MODE`: Server mode (default: remote)
- `DEBUG`: Debug mode (default: False)
- `SSL_VERIFY`: SSL verification (default: True)
- `LOG_LEVEL`: Logging level (default: INFO)
- `PORT`: Server port (default: 8000)
- `HOST`: Server host (default: 0.0.0.0)
- `OBSERVABILITY_ENABLED`: Enable observability (default: True)
- `METRICS_ENABLED`: Enable metrics (default: True)
- `TRACING_ENABLED`: Enable tracing (default: False)

### Updating Configuration

#### Update ConfigMap
```bash
ibmcloud ce configmap update --name openpages-config \
  --from-literal LOG_LEVEL=DEBUG
```

#### Update Secret
```bash
ibmcloud ce secret update --name openpages-credentials \
  --from-literal OPENPAGES_PASSWORD=new_password
```

#### Restart Application (to pick up changes)
```bash
ibmcloud ce application update --name openpages-mcp-server \
  --revision-name openpages-mcp-server-v2
```

---

## Monitoring and Troubleshooting

### Health Checks

Code Engine automatically monitors your application using the configured health probes:

```bash
# Liveness probe: /health/live
# Readiness probe: /health/ready
# Startup probe: /health/startup

# Test health endpoints
APP_URL=$(ibmcloud ce application get --name openpages-mcp-server --output url)
curl $APP_URL/health
curl $APP_URL/health/live
curl $APP_URL/health/ready
curl $APP_URL/health/startup
```

### Viewing Logs

```bash
# View recent logs
ibmcloud ce application logs --name openpages-mcp-server

# Follow logs in real-time
ibmcloud ce application logs --name openpages-mcp-server --follow

# View logs for specific instance
ibmcloud ce application logs --name openpages-mcp-server --instance <instance-name>

# Export logs to file
ibmcloud ce application logs --name openpages-mcp-server > logs.txt
```

### Metrics

```bash
# View application metrics
ibmcloud ce application get --name openpages-mcp-server

# Access Prometheus metrics endpoint
APP_URL=$(ibmcloud ce application get --name openpages-mcp-server --output url)
curl $APP_URL/metrics
```

### Common Issues

#### Application Not Starting
```bash
# Check application events
ibmcloud ce application events --name openpages-mcp-server

# Check logs for errors
ibmcloud ce application logs --name openpages-mcp-server --tail 100

# Verify configuration
ibmcloud ce configmap get --name openpages-config
ibmcloud ce secret get --name openpages-credentials
```

#### Connection to OpenPages Fails
```bash
# Test from within the application
ibmcloud ce application exec --name openpages-mcp-server \
  --command "curl -k $OPENPAGES_BASE_URL"

# Check SSL_VERIFY setting
ibmcloud ce configmap get --name openpages-config
```

#### High Memory Usage
```bash
# Check current resource usage
ibmcloud ce application get --name openpages-mcp-server

# Increase memory allocation
ibmcloud ce application update --name openpages-mcp-server --memory 4G
```

---

## Scaling and Performance

### Auto-Scaling Configuration

Code Engine automatically scales your application based on:
- Concurrent requests
- CPU usage
- Memory usage

```bash
# Update scaling parameters
ibmcloud ce application update --name openpages-mcp-server \
  --min-scale 2 \
  --max-scale 20 \
  --concurrency 100 \
  --concurrency-target 80
```

### Performance Tuning

#### CPU and Memory
```bash
# Increase resources for better performance
ibmcloud ce application update --name openpages-mcp-server \
  --cpu 2 \
  --memory 4G
```

#### Request Timeout
```bash
# Increase timeout for long-running operations
ibmcloud ce application update --name openpages-mcp-server \
  --request-timeout 600
```

#### Concurrency
```bash
# Adjust concurrent requests per instance
ibmcloud ce application update --name openpages-mcp-server \
  --concurrency 200 \
  --concurrency-target 160
```

### Cost Optimization

```bash
# Scale to zero when not in use (saves costs)
ibmcloud ce application update --name openpages-mcp-server \
  --min-scale 0

# Use smaller instances for development
ibmcloud ce application update --name openpages-mcp-server \
  --cpu 0.5 \
  --memory 1G
```

---

## Advanced Topics

### Custom Domain

```bash
# Add custom domain
ibmcloud ce application update --name openpages-mcp-server \
  --domain-mapping custom.yourdomain.com \
  --tls-secret your-tls-secret
```

### Private Endpoints

```bash
# Create application with private endpoint only
ibmcloud ce application create \
  --name openpages-mcp-server \
  --image us.icr.io/<namespace>/openpages-mcp-server:latest \
  --visibility private \
  --port 8000
```

### Blue-Green Deployment

```bash
# Deploy new version
ibmcloud ce application update --name openpages-mcp-server \
  --image us.icr.io/<namespace>/openpages-mcp-server:v2 \
  --revision-name openpages-mcp-server-v2

# Split traffic between versions
ibmcloud ce application update --name openpages-mcp-server \
  --traffic openpages-mcp-server-v1=50,openpages-mcp-server-v2=50

# Route all traffic to new version
ibmcloud ce application update --name openpages-mcp-server \
  --traffic openpages-mcp-server-v2=100
```

### Integration with IBM Cloud Services

#### Connect to IBM Cloud Databases
```bash
# Bind service credentials
ibmcloud ce application bind --name openpages-mcp-server \
  --service-instance <database-instance-name>
```

#### Use IBM Cloud Object Storage
```bash
# Create secret with COS credentials
ibmcloud ce secret create --name cos-credentials \
  --from-literal COS_ENDPOINT=<endpoint> \
  --from-literal COS_API_KEY=<api-key> \
  --from-literal COS_INSTANCE_ID=<instance-id>

# Add to application
ibmcloud ce application update --name openpages-mcp-server \
  --env-from-secret cos-credentials
```

---

## Cleanup

### Delete Application
```bash
ibmcloud ce application delete --name openpages-mcp-server
```

### Delete Secrets and ConfigMaps
```bash
ibmcloud ce secret delete --name openpages-credentials
ibmcloud ce configmap delete --name openpages-config
```

### Delete Project
```bash
ibmcloud ce project delete --name openpages-mcp-server
```

---

## Best Practices

1. **Security**
   - Always use secrets for sensitive data
   - Enable SSL_VERIFY in production
   - Use private endpoints when possible
   - Rotate credentials regularly

2. **Performance**
   - Set appropriate min/max scale values
   - Monitor metrics and adjust resources
   - Use concurrency settings effectively
   - Enable request timeout for long operations

3. **Reliability**
   - Configure health probes properly
   - Set up auto-scaling
   - Use multiple instances (min-scale > 1)
   - Monitor logs and metrics

4. **Cost Optimization**
   - Scale to zero for dev/test environments
   - Right-size CPU and memory
   - Use appropriate concurrency settings
   - Clean up unused resources

---

## Additional Resources

- [IBM Code Engine Documentation](https://cloud.ibm.com/docs/codeengine)
- [Code Engine CLI Reference](https://cloud.ibm.com/docs/codeengine?topic=codeengine-cli)
- [OpenPages MCP Server Documentation](./README.md)
- [Deployment Architecture](./DEPLOYMENT.md)

---

## Support

For issues or questions:
1. Check the [troubleshooting section](#monitoring-and-troubleshooting)
2. Review application logs
3. Consult IBM Code Engine documentation
4. Open an issue in the project repository