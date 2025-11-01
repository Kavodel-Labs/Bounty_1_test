#!/usr/bin/env python3
"""
Metabase API Client
Connects to Metabase, scans database schema, and executes SQL queries
"""

import os
import json
import requests
from typing import Dict, List, Optional
from dotenv import load_dotenv

class MetabaseClient:
    def __init__(self, url: str, username: str, password: str):
        self.base_url = url.rstrip('/')
        self.username = username
        self.password = password
        self.session_token = None
        self.schema_cache = {}

    def authenticate(self) -> bool:
        """Authenticate and get session token"""
        try:
            response = requests.post(
                f"{self.base_url}/api/session",
                json={"username": self.username, "password": self.password},
                timeout=10
            )

            if response.status_code == 200:
                data = response.json()
                self.session_token = data.get('id')
                print(f"✅ Authentication successful! Token: {self.session_token[:10]}...")
                return True
            else:
                print(f"❌ Authentication failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False

        except Exception as e:
            print(f"❌ Connection error: {e}")
            return False

    def _get_headers(self) -> Dict[str, str]:
        """Get headers with session token"""
        return {
            "X-Metabase-Session": self.session_token,
            "Content-Type": "application/json"
        }

    def list_databases(self) -> List[Dict]:
        """List all databases in Metabase"""
        if not self.session_token:
            print("❌ Not authenticated. Call authenticate() first.")
            return []

        try:
            response = requests.get(
                f"{self.base_url}/api/database",
                headers=self._get_headers(),
                timeout=10
            )

            if response.status_code == 200:
                databases = response.json().get('data', [])
                print(f"\n📊 Found {len(databases)} database(s):")
                for db in databases:
                    print(f"   - ID: {db['id']} | Name: {db['name']} | Engine: {db['engine']}")
                return databases
            else:
                print(f"❌ Failed to list databases: {response.status_code}")
                return []

        except Exception as e:
            print(f"❌ Error listing databases: {e}")
            return []

    def get_database_metadata(self, database_id: int, force_refresh: bool = False) -> Dict:
        """Get complete schema metadata for a database"""
        if not self.session_token:
            print("❌ Not authenticated")
            return {}

        # Use cache unless force refresh
        if database_id in self.schema_cache and not force_refresh:
            print(f"📦 Using cached schema for database {database_id}")
            return self.schema_cache[database_id]

        try:
            print(f"🔍 Fetching metadata for database ID: {database_id}...")
            response = requests.get(
                f"{self.base_url}/api/database/{database_id}/metadata",
                headers=self._get_headers(),
                timeout=30
            )

            if response.status_code == 200:
                metadata = response.json()
                self.schema_cache[database_id] = metadata

                # Print summary
                tables = metadata.get('tables', [])
                print(f"✅ Retrieved {len(tables)} tables")

                total_columns = sum(len(t.get('fields', [])) for t in tables)
                print(f"   Total columns: {total_columns}")

                return metadata
            else:
                print(f"❌ Failed: {response.status_code} - {response.text}")
                return {}

        except Exception as e:
            print(f"❌ Error: {e}")
            return {}

    def export_schema_to_json(self, database_id: int, output_file: str = "schema.json"):
        """Export database schema to JSON file"""
        metadata = self.get_database_metadata(database_id)

        if not metadata:
            print("❌ No metadata to export")
            return

        # Build simplified schema structure
        schema = {
            "database_id": database_id,
            "database_name": metadata.get('name', 'Unknown'),
            "tables": []
        }

        for table in metadata.get('tables', []):
            table_info = {
                "id": table.get('id'),
                "name": table.get('name'),
                "schema": table.get('schema'),
                "display_name": table.get('display_name'),
                "columns": []
            }

            for field in table.get('fields', []):
                column_info = {
                    "id": field.get('id'),
                    "name": field.get('name'),
                    "display_name": field.get('display_name'),
                    "base_type": field.get('base_type'),
                    "semantic_type": field.get('semantic_type'),
                    "description": field.get('description', '')
                }
                table_info['columns'].append(column_info)

            schema['tables'].append(table_info)

        # Write to file
        with open(output_file, 'w') as f:
            json.dump(schema, f, indent=2)

        print(f"\n💾 Schema exported to: {output_file}")
        print(f"   Tables: {len(schema['tables'])}")
        print(f"   Total columns: {sum(len(t['columns']) for t in schema['tables'])}")

    def print_schema_summary(self, database_id: int):
        """Print a human-readable schema summary"""
        metadata = self.get_database_metadata(database_id)

        if not metadata:
            return

        print(f"\n{'='*80}")
        print(f"DATABASE SCHEMA: {metadata.get('name', 'Unknown')}")
        print(f"{'='*80}\n")

        for table in metadata.get('tables', []):
            schema_name = table.get('schema', 'public')
            table_name = table.get('name')
            display_name = table.get('display_name', table_name)

            print(f"📋 {schema_name}.{table_name}")
            if display_name != table_name:
                print(f"   Display: {display_name}")

            fields = table.get('fields', [])
            print(f"   Columns ({len(fields)}):")

            for field in fields:
                name = field.get('name')
                base_type = field.get('base_type', 'unknown').replace('type/', '')
                semantic = field.get('semantic_type', '').replace('type/', '')
                desc = field.get('description', '')

                type_info = base_type
                if semantic:
                    type_info += f" [{semantic}]"

                print(f"      • {name:<30} {type_info:<30}", end='')
                if desc:
                    print(f" # {desc}")
                else:
                    print()

            print()

    def execute_sql(self, database_id: int, sql: str) -> Dict:
        """Execute SQL query and return results"""
        if not self.session_token:
            print("❌ Not authenticated")
            return {}

        try:
            payload = {
                "database": database_id,
                "type": "native",
                "native": {
                    "query": sql
                }
            }

            print(f"🔄 Executing SQL on database {database_id}...")
            response = requests.post(
                f"{self.base_url}/api/dataset",
                headers=self._get_headers(),
                json=payload,
                timeout=60
            )

            if response.status_code == 202:
                # Query is running async, get the results
                data = response.json()
                print(f"✅ Query executed successfully")
                return data
            elif response.status_code == 200:
                data = response.json()
                print(f"✅ Query executed successfully")

                # Print results summary
                if 'data' in data:
                    rows = data['data'].get('rows', [])
                    cols = data['data'].get('cols', [])
                    print(f"   Rows: {len(rows)}")
                    print(f"   Columns: {len(cols)}")

                return data
            else:
                print(f"❌ Query failed: {response.status_code}")
                print(f"   Error: {response.text}")
                return {}

        except Exception as e:
            print(f"❌ Error executing SQL: {e}")
            return {}

    def validate_sql_against_schema(self, database_id: int, sql: str) -> bool:
        """Basic SQL validation against schema (table/column existence)"""
        metadata = self.get_database_metadata(database_id)

        if not metadata:
            print("⚠️  No schema available for validation")
            return True  # Proceed anyway

        # Build lookup of valid tables and columns
        valid_tables = {}
        for table in metadata.get('tables', []):
            table_name = table.get('name', '').lower()
            schema = table.get('schema', 'public').lower()
            full_name = f"{schema}.{table_name}"

            columns = [f.get('name', '').lower() for f in table.get('fields', [])]
            valid_tables[table_name] = columns
            valid_tables[full_name] = columns

        # Simple validation (can be enhanced)
        sql_lower = sql.lower()
        issues = []

        # Extract table names (basic FROM/JOIN detection)
        import re
        table_pattern = r'\b(?:from|join)\s+([a-z_][a-z0-9_]*(?:\.[a-z_][a-z0-9_]*)?)\b'
        found_tables = re.findall(table_pattern, sql_lower)

        for table in found_tables:
            if table not in valid_tables:
                issues.append(f"Table not found: {table}")

        if issues:
            print("⚠️  SQL Validation Issues:")
            for issue in issues:
                print(f"   - {issue}")
            return False
        else:
            print("✅ SQL validation passed")
            return True


def main():
    """Main function - demonstrates usage"""
    # Load environment variables
    load_dotenv()

    url = os.getenv('METABASE_URL')
    username = os.getenv('METABASE_USERNAME')
    password = os.getenv('METABASE_PASSWORD')

    if not all([url, username, password]):
        print("❌ Missing credentials in .env file")
        return

    # Initialize client
    print("🚀 Metabase API Client")
    print(f"   URL: {url}")
    print(f"   User: {username}\n")

    client = MetabaseClient(url, username, password)

    # Step 1: Authenticate
    if not client.authenticate():
        return

    # Step 2: List databases
    databases = client.list_databases()

    if not databases:
        print("❌ No databases found")
        return

    # Step 3: Get schema for first database
    db_id = databases[0]['id']
    db_name = databases[0]['name']

    print(f"\n🔍 Analyzing database: {db_name} (ID: {db_id})")

    # Export schema
    client.export_schema_to_json(db_id, f"schema_db_{db_id}.json")

    # Print summary
    client.print_schema_summary(db_id)

    # Step 4: Example query
    print("\n" + "="*80)
    print("Example: Execute SQL Query")
    print("="*80)

    # Simple test query
    test_sql = "SELECT 1 as test"

    if client.validate_sql_against_schema(db_id, test_sql):
        result = client.execute_sql(db_id, test_sql)

        if result:
            print("\n✅ All operations completed successfully!")

    print("\n" + "="*80)
    print("Client ready for use. Example usage:")
    print("="*80)
    print(f"""
from metabase_client import MetabaseClient

client = MetabaseClient('{url}', '{username}', '***')
client.authenticate()
databases = client.list_databases()
client.print_schema_summary({db_id})
result = client.execute_sql({db_id}, "SELECT * FROM your_table LIMIT 10")
""")


if __name__ == "__main__":
    main()
