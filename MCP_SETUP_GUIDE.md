# MCP Database Integration Guide

## Option 1: PostgreSQL MCP Server (Recommended)

### Setup
```bash
# Install Node.js if not already installed
# Then the MCP server will be auto-installed via npx

# Create config file at: ~/.config/claude/claude_desktop_config.json
```

### Optimized Configuration

```json
{
  "mcpServers": {
    "metabase-db": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://USERNAME:PASSWORD@HOST:PORT/DATABASE"
      ],
      "env": {
        "POSTGRES_MAX_ROWS": "100",
        "POSTGRES_QUERY_TIMEOUT": "30000"
      }
    }
  }
}
```

### Token Optimization Settings

**Problem**: MCP returns too much data, consuming tokens

**Solutions**:

1. **Limit row returns** (add to config):
```json
"env": {
  "POSTGRES_MAX_ROWS": "100",           // Limit query results
  "POSTGRES_QUERY_TIMEOUT": "30000",    // 30 second timeout
  "POSTGRES_STATEMENT_TIMEOUT": "30s"   // PostgreSQL statement timeout
}
```

2. **Use query constraints**:
```sql
-- Instead of:
SELECT * FROM users

-- Always use LIMIT:
SELECT * FROM users LIMIT 10
```

3. **Schema filtering** (if server supports):
```json
"env": {
  "POSTGRES_SCHEMA": "public",          // Only show public schema
  "POSTGRES_TABLES": "users,orders"     // Only specific tables
}
```

---

## Option 2: Custom MCP Server with Schema Caching

If token usage is still too high, I can create a **custom lightweight MCP server** that:

- ✅ Caches schema locally (loaded once)
- ✅ Returns only column names/types (not data)
- ✅ Validates SQL before execution
- ✅ Limits result sets automatically

Would you like me to build this?

---

## Current Token Usage Issues - Diagnosis

### Check what MCP is sending:

1. **Schema size**:
   - How many tables?
   - How many columns total?
   - Large schemas = high token usage

2. **Auto-query behavior**:
   - Is MCP fetching sample data automatically?
   - Check if it's caching schema or re-fetching

3. **Result size**:
   - Are queries returning thousands of rows?

---

## Your Connection Details Needed

To set up MCP for your Metabase database, I need:

```env
# Metabase stores data in PostgreSQL/MySQL
# Connect to the APPLICATION database (not Metabase's internal DB)

DB_TYPE=postgresql          # or mysql
DB_HOST=your-host.com
DB_PORT=5432               # or 3306 for MySQL
DB_NAME=your_app_database
DB_USER=readonly_user      # Use read-only if available
DB_PASSWORD=***
```

**Where to find this?**
- In Metabase: Admin → Databases → Your Database → View Connection Details
- Or ask your DBA for connection string

---

## Quick Test

Once configured, Claude will have these MCP tools:

- `mcp__postgres__query` - Execute SQL
- `mcp__postgres__list_tables` - List all tables
- `mcp__postgres__describe_table` - Get table schema

**Example prompt after setup:**
> "List all tables in the database"
> "Describe the users table"
> "Query: SELECT * FROM users LIMIT 5"

---

## Next Steps

**Option A**: Share your existing MCP config → I'll optimize it

**Option B**: Provide database credentials → I'll create optimized config

**Option C**: Build custom lightweight MCP server → Full control over token usage

Which would you like?
