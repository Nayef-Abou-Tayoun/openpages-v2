#!/bin/bash

# ============================================================================
# IBM Code Engine Deployment Script
# ============================================================================
# This script automates the deployment of OpenPages MCP Server to IBM Code Engine
#
# Usage:
#   ./deploy-code-engine.sh [options]
#
# Options:
#   --project-name NAME       Code Engine project name (default: openpages-mcp-server)
#   --app-name NAME          Application name (default: openpages-mcp-server)
#   --region REGION          IBM Cloud region (default: us-south)
#   --resource-group GROUP   Resource group (default: Default)
#   --image IMAGE            Container image (required if not building from source)
#   --build-from-source      Build from source code instead of using pre-built image
#   --namespace NAMESPACE    IBM Container Registry namespace (for ICR deployments)
#   --min-scale NUM          Minimum instances (default: 1)
#   --max-scale NUM          Maximum instances (default: 5)
#   --cpu NUM                CPU allocation (default: 1)
#   --memory SIZE            Memory allocation (default: 2G)
#   --env-file FILE          Environment file (default: .env)
#   --skip-config            Skip creating configmap and secret
#   --help                   Show this help message
#
# Examples:
#   # Deploy from IBM Container Registry
#   ./deploy-code-engine.sh --namespace my-namespace
#
#   # Deploy from source code
#   ./deploy-code-engine.sh --build-from-source
#
#   # Deploy with custom settings
#   ./deploy-code-engine.sh --min-scale 2 --max-scale 10 --cpu 2 --memory 4G
#
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PROJECT_NAME="openpages-mcp-server"
APP_NAME="openpages-mcp-server"
REGION="us-south"
RESOURCE_GROUP="Default"
IMAGE=""
BUILD_FROM_SOURCE=false
NAMESPACE=""
MIN_SCALE=1
MAX_SCALE=5
CPU=1
MEMORY="2G"
ENV_FILE=".env"
SKIP_CONFIG=false

# ============================================================================
# Helper Functions
# ============================================================================

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    sed -n '/^# Usage:/,/^# ============================================================================$/p' "$0" | sed 's/^# //'
    exit 0
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 is not installed. Please install it first."
        exit 1
    fi
}

# ============================================================================
# Parse Command Line Arguments
# ============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --app-name)
            APP_NAME="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        --image)
            IMAGE="$2"
            shift 2
            ;;
        --build-from-source)
            BUILD_FROM_SOURCE=true
            shift
            ;;
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --min-scale)
            MIN_SCALE="$2"
            shift 2
            ;;
        --max-scale)
            MAX_SCALE="$2"
            shift 2
            ;;
        --cpu)
            CPU="$2"
            shift 2
            ;;
        --memory)
            MEMORY="$2"
            shift 2
            ;;
        --env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        --skip-config)
            SKIP_CONFIG=true
            shift
            ;;
        --help)
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ============================================================================
# Validation
# ============================================================================

print_info "Validating prerequisites..."

# Check required commands
check_command "ibmcloud"
check_command "docker"

# Check if Code Engine plugin is installed
if ! ibmcloud plugin list | grep -q "code-engine"; then
    print_error "Code Engine plugin is not installed."
    print_info "Install it with: ibmcloud plugin install code-engine"
    exit 1
fi

# Check environment file
if [ ! -f "$ENV_FILE" ]; then
    print_error "Environment file not found: $ENV_FILE"
    print_info "Create one from .env.example: cp .env.example .env"
    exit 1
fi

# Validate image or source build
if [ "$BUILD_FROM_SOURCE" = false ] && [ -z "$IMAGE" ] && [ -z "$NAMESPACE" ]; then
    print_error "Either --image, --namespace (for ICR), or --build-from-source must be specified"
    exit 1
fi

print_success "Prerequisites validated"

# ============================================================================
# IBM Cloud Login and Setup
# ============================================================================

print_info "Checking IBM Cloud login status..."

if ! ibmcloud target &> /dev/null; then
    print_warning "Not logged in to IBM Cloud"
    print_info "Logging in..."
    ibmcloud login
fi

print_info "Targeting resource group: $RESOURCE_GROUP"
ibmcloud target -g "$RESOURCE_GROUP"

print_info "Targeting region: $REGION"
ibmcloud target -r "$REGION"

print_success "IBM Cloud setup complete"

# ============================================================================
# Create or Select Code Engine Project
# ============================================================================

print_info "Setting up Code Engine project: $PROJECT_NAME"

if ibmcloud ce project get --name "$PROJECT_NAME" &> /dev/null; then
    print_info "Project already exists, selecting it..."
    ibmcloud ce project select --name "$PROJECT_NAME"
else
    print_info "Creating new project..."
    ibmcloud ce project create --name "$PROJECT_NAME"
fi

print_success "Code Engine project ready"

# ============================================================================
# Build and Push Image (if using ICR)
# ============================================================================

if [ -n "$NAMESPACE" ] && [ -z "$IMAGE" ]; then
    print_info "Building and pushing image to IBM Container Registry..."
    
    # Login to ICR
    ibmcloud cr login
    
    # Create namespace if it doesn't exist
    if ! ibmcloud cr namespace-list | grep -q "$NAMESPACE"; then
        print_info "Creating namespace: $NAMESPACE"
        ibmcloud cr namespace-add "$NAMESPACE"
    fi
    
    # Build and push image
    IMAGE="${REGION}.icr.io/${NAMESPACE}/${APP_NAME}:latest"
    print_info "Building image: $IMAGE"
    docker build -t "$IMAGE" .
    
    print_info "Pushing image to registry..."
    docker push "$IMAGE"
    
    # Create registry secret
    print_info "Creating registry secret..."
    API_KEY=$(ibmcloud iam api-key-create "${APP_NAME}-key" --output json | jq -r '.apikey')
    
    if ibmcloud ce registry get --name icr-secret &> /dev/null; then
        print_info "Registry secret already exists"
    else
        ibmcloud ce registry create --name icr-secret \
            --server "${REGION}.icr.io" \
            --username iamapikey \
            --password "$API_KEY"
    fi
    
    REGISTRY_SECRET="icr-secret"
    print_success "Image built and pushed successfully"
fi

# ============================================================================
# Create ConfigMap and Secret
# ============================================================================

if [ "$SKIP_CONFIG" = false ]; then
    print_info "Creating configuration..."
    
    # Source environment file
    set -a
    source "$ENV_FILE"
    set +a
    
    # Create or update ConfigMap
    print_info "Creating/updating ConfigMap..."
    CONFIGMAP_ARGS=(
        --from-literal "SERVER_MODE=${SERVER_MODE:-remote}"
        --from-literal "DEBUG=${DEBUG:-False}"
        --from-literal "SSL_VERIFY=${SSL_VERIFY:-True}"
        --from-literal "LOG_LEVEL=${LOG_LEVEL:-INFO}"
        --from-literal "PORT=${PORT:-8000}"
        --from-literal "HOST=${HOST:-0.0.0.0}"
        --from-literal "OBSERVABILITY_ENABLED=${OBSERVABILITY_ENABLED:-True}"
        --from-literal "METRICS_ENABLED=${METRICS_ENABLED:-True}"
        --from-literal "TRACING_ENABLED=${TRACING_ENABLED:-False}"
    )
    
    if ibmcloud ce configmap get --name openpages-config &> /dev/null; then
        ibmcloud ce configmap update --name openpages-config "${CONFIGMAP_ARGS[@]}"
    else
        ibmcloud ce configmap create --name openpages-config "${CONFIGMAP_ARGS[@]}"
    fi
    
    # Create or update Secret
    print_info "Creating/updating Secret..."
    SECRET_ARGS=(
        --from-literal "OPENPAGES_BASE_URL=${OPENPAGES_BASE_URL}"
        --from-literal "OPENPAGES_AUTHENTICATION_TYPE=${OPENPAGES_AUTHENTICATION_TYPE}"
    )
    
    # Add authentication-specific variables
    if [ "$OPENPAGES_AUTHENTICATION_TYPE" = "basic" ] || [ "$OPENPAGES_AUTHENTICATION_TYPE" = "form" ]; then
        SECRET_ARGS+=(
            --from-literal "OPENPAGES_USERNAME=${OPENPAGES_USERNAME}"
            --from-literal "OPENPAGES_PASSWORD=${OPENPAGES_PASSWORD}"
        )
    elif [ "$OPENPAGES_AUTHENTICATION_TYPE" = "bearer" ]; then
        SECRET_ARGS+=(
            --from-literal "OPENPAGES_APIKEY=${OPENPAGES_APIKEY}"
            --from-literal "OPENPAGES_AUTHENTICATION_URL=${OPENPAGES_AUTHENTICATION_URL}"
        )
    fi
    
    if ibmcloud ce secret get --name openpages-credentials &> /dev/null; then
        ibmcloud ce secret update --name openpages-credentials "${SECRET_ARGS[@]}"
    else
        ibmcloud ce secret create --name openpages-credentials "${SECRET_ARGS[@]}"
    fi
    
    print_success "Configuration created"
fi

# ============================================================================
# Deploy Application
# ============================================================================

print_info "Deploying application: $APP_NAME"

DEPLOY_ARGS=(
    --name "$APP_NAME"
    --port 8000
    --min-scale "$MIN_SCALE"
    --max-scale "$MAX_SCALE"
    --cpu "$CPU"
    --memory "$MEMORY"
    --concurrency 100
    --concurrency-target 80
    --request-timeout 300
    --env-from-configmap openpages-config
    --env-from-secret openpages-credentials
)

# Add health probes
DEPLOY_ARGS+=(
    --probe-live "type=http,path=/health/live,port=8000,interval=30,timeout=10,failure-threshold=3"
    --probe-ready "type=http,path=/health/ready,port=8000,interval=10,timeout=5,failure-threshold=3"
)

# Add image or build source
if [ "$BUILD_FROM_SOURCE" = true ]; then
    DEPLOY_ARGS+=(--build-source .)
elif [ -n "$IMAGE" ]; then
    DEPLOY_ARGS+=(--image "$IMAGE")
    if [ -n "$REGISTRY_SECRET" ]; then
        DEPLOY_ARGS+=(--registry-secret "$REGISTRY_SECRET")
    fi
fi

# Check if application exists
if ibmcloud ce application get --name "$APP_NAME" &> /dev/null; then
    print_info "Application exists, updating..."
    ibmcloud ce application update "${DEPLOY_ARGS[@]}"
else
    print_info "Creating new application..."
    ibmcloud ce application create "${DEPLOY_ARGS[@]}"
fi

print_success "Application deployed successfully"

# ============================================================================
# Display Deployment Information
# ============================================================================

print_info "Retrieving deployment information..."

APP_URL=$(ibmcloud ce application get --name "$APP_NAME" --output url)

echo ""
echo "============================================================================"
echo -e "${GREEN}Deployment Complete!${NC}"
echo "============================================================================"
echo ""
echo "Application Name:    $APP_NAME"
echo "Project Name:        $PROJECT_NAME"
echo "Region:              $REGION"
echo "Application URL:     $APP_URL"
echo ""
echo "Health Endpoints:"
echo "  - Comprehensive:   $APP_URL/health"
echo "  - Readiness:       $APP_URL/health/ready"
echo "  - Liveness:        $APP_URL/health/live"
echo "  - Startup:         $APP_URL/health/startup"
echo "  - Metrics:         $APP_URL/metrics"
echo ""
echo "Useful Commands:"
echo "  - View logs:       ibmcloud ce application logs --name $APP_NAME --follow"
echo "  - Get status:      ibmcloud ce application get --name $APP_NAME"
echo "  - Update app:      ibmcloud ce application update --name $APP_NAME [options]"
echo "  - Delete app:      ibmcloud ce application delete --name $APP_NAME"
echo ""
echo "============================================================================"
echo ""

# Test health endpoint
print_info "Testing health endpoint..."
if curl -s -f "$APP_URL/health" > /dev/null; then
    print_success "Health check passed!"
else
    print_warning "Health check failed. The application may still be starting up."
    print_info "Check logs with: ibmcloud ce application logs --name $APP_NAME"
fi

print_success "Deployment script completed"

# Made with Bob
