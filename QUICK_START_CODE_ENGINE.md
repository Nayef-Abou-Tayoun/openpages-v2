# Quick Start: Deploy to IBM Code Engine

This guide will get your OpenPages MCP Server running on IBM Code Engine in minutes.

## Prerequisites

- IBM Cloud account
- IBM Cloud CLI installed
- Code Engine plugin: `ibmcloud plugin install code-engine`
- Your OpenPages credentials

## Step 1: Add Missing Environment Variables

You already have most variables configured! Just add these missing ones:

### Using IBM Cloud Console (Easiest)

1. Go to your Code Engine project in IBM Cloud Console
2. Select your application: `openpages-mcp-v2`
3. Click **"Environment variables"** tab
4. Click **"Add"** button and add each of these:

| Name | Value | Type |
|------|-------|------|
| `SERVER_MODE` | `remote` | Literal |
| `PORT` | `8000` | Literal |
| `HOST` | `0.0.0.0` | Literal |
| `OBSERVABILITY_ENABLED` | `True` | Literal |
| `METRICS_ENABLED` | `True` | Literal |
| `TRACING_ENABLED` | `False` | Literal |

5. Click **"Save"** - your application will automatically restart

### Using IBM Cloud CLI (Alternative)

```bash
# Login to IBM Cloud
ibmcloud login

# Select your project
ibmcloud ce project select --name <your-project-name>

# Add all missing variables at once
ibmcloud ce application update --name openpages-mcp-v2 \
  --env SERVER_MODE=remote \
  --env PORT=8000 \
  --env HOST=0.0.0.0 \
  --env OBSERVABILITY_ENABLED=True \
  --env METRICS_ENABLED=True \
  --env TRACING_ENABLED=False
```

## Step 2: Verify Deployment

Your application URL (based on your current setup):
```
https://openpages-mcp-v2.271oe4tvp6su.us-south.codeengine.appdomain.cloud
```

Test the health endpoint:
```bash
curl https://openpages-mcp-v2.271oe4tvp6su.us-south.codeengine.appdomain.cloud/health
```

Expected response:
```json
{
  "status": "healthy",
  "openpages_connection": "ok",
  "version": "1.0.0"
}
```

## Step 3: Test MCP Endpoints

```bash
# Set your app URL
APP_URL="https://openpages-mcp-v2.271oe4tvp6su.us-south.codeengine.appdomain.cloud"

# Test root endpoint
curl $APP_URL/

# Test health endpoints
curl $APP_URL/health
curl $APP_URL/health/ready
curl $APP_URL/health/live

# Test metrics endpoint
curl $APP_URL/metrics
```

## Step 4: View Logs

```bash
# View recent logs
ibmcloud ce application logs --name openpages-mcp-v2

# Follow logs in real-time
ibmcloud ce application logs --name openpages-mcp-v2 --follow
```

## Common Issues & Solutions

### Issue: Application not starting

**Solution:** Check logs for errors
```bash
ibmcloud ce application logs --name openpages-mcp-v2 --tail 50
```

### Issue: Health check fails

**Solution:** Verify all required variables are set
```bash
ibmcloud ce application get --name openpages-mcp-v2
```

### Issue: Can't connect to OpenPages

**Solution:** Verify OpenPages URL and credentials
```bash
# Check if OpenPages is accessible
curl -k http://useast.services.cloud.techzone.ibm.com:22816/openpages/
```

## Scaling Your Application

```bash
# Scale to handle more traffic
ibmcloud ce application update --name openpages-mcp-v2 \
  --min-scale 2 \
  --max-scale 10

# Scale to zero when not in use (saves costs)
ibmcloud ce application update --name openpages-mcp-v2 \
  --min-scale 0
```

## Updating Your Application

```bash
# Update to new image version
ibmcloud ce application update --name openpages-mcp-v2 \
  --image us.icr.io/<namespace>/openpages-mcp-server:latest

# Or rebuild from source
ibmcloud ce application update --name openpages-mcp-v2 \
  --build-source .
```

## Next Steps

1. ✅ Configure your MCP client to use the application URL
2. ✅ Test tool invocations through MCP protocol
3. ✅ Monitor metrics at `/metrics` endpoint
4. ✅ Set up alerts for health check failures
5. ✅ Review [Full Deployment Guide](docs/CODE_ENGINE_DEPLOYMENT.md)

## Useful Commands

```bash
# Get application URL
ibmcloud ce application get --name openpages-mcp-v2 --output url

# Check application status
ibmcloud ce application get --name openpages-mcp-v2

# View application events
ibmcloud ce application events --name openpages-mcp-v2

# Restart application
ibmcloud ce application update --name openpages-mcp-v2

# Delete application
ibmcloud ce application delete --name openpages-mcp-v2
```

## Support

- 📖 [Full Documentation](docs/CODE_ENGINE_DEPLOYMENT.md)
- 🔧 [Variable Reference](CODE_ENGINE_VARIABLES.md)
- 📝 [Main README](README.md)
- 🔐 [Authentication Guide](docs/AUTHENTICATION.md)

---

**That's it!** Your OpenPages MCP Server should now be running on IBM Code Engine. 🚀