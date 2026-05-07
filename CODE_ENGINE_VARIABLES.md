# IBM Code Engine Environment Variables Reference

## Current Variables in Your Code Engine Application

Based on your screenshot, you have these variables configured:

| Variable Name | Current Value | Status |
|--------------|---------------|---------|
| `SSL_VERIFY` | False | ✅ Set |
| `CE_API_BASE_URL` | https://api.private.us-south.codeengine.cloud.ibm.com | ✅ Set (Code Engine) |
| `CE_PROJECT_ID` | 4f55c5f6-5cad-4c62-9ec1-ed86141fb927 | ✅ Set (Code Engine) |
| `CE_APP` | openpages-mcp-v2 | ✅ Set (Code Engine) |
| `CE_REGION` | us-south | ✅ Set (Code Engine) |
| `CE_SUBDOMAIN` | 271oe4tvp6su | ✅ Set (Code Engine) |
| `OPENPAGES_PASSWORD` | OpenPagesAdministrator | ✅ Set |
| `CE_DOMAIN` | us-south.codeengine.appdomain.cloud | ✅ Set (Code Engine) |
| `OPENPAGES_AUTHENTICATION_TYPE` | basic | ✅ Set |
| `OPENPAGES_BASE_URL` | http://useast.services.cloud.techzone.ibm.com:22816/openpages/ | ✅ Set |
| `LOG_LEVEL` | INFO | ✅ Set |
| `DEBUG` | False | ✅ Set |
| `OPENPAGES_USERNAME` | OpenPagesAdministrator | ✅ Set |

## Required Variables - Status Check

### ✅ Already Configured (Good!)
- `OPENPAGES_BASE_URL` - Your OpenPages server URL
- `OPENPAGES_AUTHENTICATION_TYPE` - Set to "basic"
- `OPENPAGES_USERNAME` - Your username
- `OPENPAGES_PASSWORD` - Your password
- `SSL_VERIFY` - Set to False (appropriate for TechZone)
- `DEBUG` - Set to False
- `LOG_LEVEL` - Set to INFO

### ⚠️ Missing Variables (Need to Add)

Add these variables to your Code Engine application:

```bash
# Server Configuration
SERVER_MODE=remote
PORT=8000
HOST=0.0.0.0

# Observability
OBSERVABILITY_ENABLED=True
METRICS_ENABLED=True
TRACING_ENABLED=False

# Rate Limiting (Optional)
RATE_LIMIT_ENABLED=True
RATE_LIMIT_REQUESTS_PER_MINUTE=60
RATE_LIMIT_BURST_SIZE=10
```

## How to Add Missing Variables

### Option 1: Using IBM Cloud Console
1. Go to your Code Engine project
2. Select your application: `openpages-mcp-v2`
3. Click "Environment variables" tab
4. Click "Add" button
5. Add each variable with "Literal" type

### Option 2: Using IBM Cloud CLI

```bash
# Login and select project
ibmcloud login
ibmcloud ce project select --name <your-project-name>

# Add missing variables
ibmcloud ce application update --name openpages-mcp-v2 \
  --env SERVER_MODE=remote \
  --env PORT=8000 \
  --env HOST=0.0.0.0 \
  --env OBSERVABILITY_ENABLED=True \
  --env METRICS_ENABLED=True \
  --env TRACING_ENABLED=False \
  --env RATE_LIMIT_ENABLED=True \
  --env RATE_LIMIT_REQUESTS_PER_MINUTE=60 \
  --env RATE_LIMIT_BURST_SIZE=10
```

### Option 3: Using ConfigMap (Recommended for Production)

```bash
# Create ConfigMap with non-sensitive settings
ibmcloud ce configmap create --name openpages-config \
  --from-literal SERVER_MODE=remote \
  --from-literal PORT=8000 \
  --from-literal HOST=0.0.0.0 \
  --from-literal DEBUG=False \
  --from-literal SSL_VERIFY=False \
  --from-literal LOG_LEVEL=INFO \
  --from-literal OBSERVABILITY_ENABLED=True \
  --from-literal METRICS_ENABLED=True \
  --from-literal TRACING_ENABLED=False \
  --from-literal RATE_LIMIT_ENABLED=True \
  --from-literal RATE_LIMIT_REQUESTS_PER_MINUTE=60 \
  --from-literal RATE_LIMIT_BURST_SIZE=10

# Create Secret with sensitive credentials
ibmcloud ce secret create --name openpages-credentials \
  --from-literal OPENPAGES_BASE_URL=http://useast.services.cloud.techzone.ibm.com:22816/openpages/ \
  --from-literal OPENPAGES_AUTHENTICATION_TYPE=basic \
  --from-literal OPENPAGES_USERNAME=OpenPagesAdministrator \
  --from-literal OPENPAGES_PASSWORD=OpenPagesAdministrator

# Update application to use ConfigMap and Secret
ibmcloud ce application update --name openpages-mcp-v2 \
  --env-from-configmap openpages-config \
  --env-from-secret openpages-credentials
```

## Your Application URL

Based on your variables, your application should be accessible at:
```
https://openpages-mcp-v2.271oe4tvp6su.us-south.codeengine.appdomain.cloud
```

## Health Check Endpoints

Once deployed, test these endpoints:

```bash
# Get your app URL
APP_URL="https://openpages-mcp-v2.271oe4tvp6su.us-south.codeengine.appdomain.cloud"

# Test health endpoints
curl $APP_URL/health
curl $APP_URL/health/ready
curl $APP_URL/health/live
curl $APP_URL/metrics
```

## Quick Deployment Commands

```bash
# View application status
ibmcloud ce application get --name openpages-mcp-v2

# View logs
ibmcloud ce application logs --name openpages-mcp-v2 --follow

# Restart application
ibmcloud ce application update --name openpages-mcp-v2

# Scale application
ibmcloud ce application update --name openpages-mcp-v2 \
  --min-scale 1 \
  --max-scale 5
```

## Troubleshooting

### If application is not starting:
```bash
# Check logs
ibmcloud ce application logs --name openpages-mcp-v2

# Check events
ibmcloud ce application events --name openpages-mcp-v2

# Verify environment variables
ibmcloud ce application get --name openpages-mcp-v2
```

### If health checks fail:
1. Verify PORT is set to 8000
2. Verify HOST is set to 0.0.0.0
3. Check application logs for errors
4. Ensure OpenPages URL is accessible from Code Engine

## Next Steps

1. ✅ Add missing environment variables (see above)
2. ✅ Restart your application
3. ✅ Test health endpoints
4. ✅ Test MCP protocol endpoints
5. ✅ Monitor logs for any errors

## Additional Resources

- [Full Deployment Guide](docs/CODE_ENGINE_DEPLOYMENT.md)
- [Authentication Guide](docs/AUTHENTICATION.md)
- [Main README](README.md)