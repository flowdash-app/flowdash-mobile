# n8n API Capabilities

Based on the [n8n API Reference](https://docs.n8n.io/api/api-reference/), here's what you can fetch and do:

## Available Endpoints

### 1. **Workflows** ✅ (Already Implemented)
- **GET `/workflows`** - List all workflows
- **GET `/workflows/:id`** - Get workflow by ID
- **POST `/workflows`** - Create new workflow
- **PATCH `/workflows/:id`** - Update workflow (we use for toggle active/inactive)
- **DELETE `/workflows/:id`** - Delete workflow

**Response includes:**
- Workflow ID, name, description
- Active status (enabled/disabled)
- Created/updated timestamps
- Workflow configuration/nodes

### 2. **Executions** ⚠️ (Not Yet Implemented)
- **GET `/executions`** - List executions
  - Query parameters:
    - `workflowId` - Filter by specific workflow
    - `status` - Filter by status (success, error, running, etc.)
    - `limit` - Results per page (default: 100, max: 250)
    - `cursor` - Pagination cursor for next page
  - Response includes:
    - Execution ID
    - Workflow ID
    - Status (success, error, running, waiting, canceled)
    - Started/stopped timestamps
    - Duration
    - Error message (if failed)
    - Execution data/results

- **GET `/executions/:id`** - Get execution details
  - Full execution information including all node outputs

- **DELETE `/executions/:id`** - Delete execution

**Pagination:**
- Uses cursor-based pagination
- Response includes `nextCursor` when more results available
- Default: 100 results per page
- Maximum: 250 results per page

### 3. **Credentials** (Not Implemented)
- **GET `/credentials`** - List credentials
- **GET `/credentials/:id`** - Get credential by ID
- **POST `/credentials`** - Create credential
- **PATCH `/credentials/:id`** - Update credential
- **DELETE `/credentials/:id`** - Delete credential

### 4. **Users & Roles** (Not Implemented)
- User management endpoints
- Role assignment endpoints

### 5. **Tags** (Not Implemented)
- Tag management for organizing workflows

## Authentication

All API requests require authentication via:
- **Header**: `X-N8N-API-KEY: <your-api-key>`
- API keys are generated in the n8n instance settings

## Pagination Pattern

```json
{
  "data": [...],
  "nextCursor": "eyJpZCI6IjEyMzQ1Njc4OTAifQ=="
}
```

To get next page:
```
GET /executions?cursor=eyJpZCI6IjEyMzQ1Njc4OTAifQ==
```

## Implementation Status

✅ **Implemented:**
- Workflow listing
- Workflow details
- Workflow toggle (activate/deactivate)

⚠️ **Ready to Implement:**
- Execution history with pagination
- Execution details
- Execution filtering by workflow

❌ **Not Planned:**
- Credential management
- User management
- Tag management
- Workflow creation/editing (via API)

## Next Steps for Execution History

1. Add execution endpoints to `WorkflowRemoteDataSource`
2. Add execution repository methods
3. Create execution providers with pagination support
4. Update `WorkflowDetailsPage` to display execution history
5. Implement infinite scroll or "Load More" for pagination

