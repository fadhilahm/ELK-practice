#!/bin/bash

echo "=== Testing Logstash ==="
echo ""

# Method 1: Check Logstash health
echo "1. Checking Logstash health status..."
curl -s http://localhost:9600/_node/stats | jq '.' || echo "Logstash may not be running or jq is not installed"
echo ""

# Method 2: Test TCP input
echo "2. Testing TCP input (port 5000)..."
echo "Sending test log via TCP..."
echo '{"message": "Test log from TCP", "timestamp": "'$(date -Iseconds)'", "level": "INFO"}' | nc localhost 5000
echo "Log sent via TCP"
echo ""

# Method 3: Test UDP input
echo "3. Testing UDP input (port 5000)..."
echo "Sending test log via UDP..."
echo '{"message": "Test log from UDP", "timestamp": "'$(date -Iseconds)'", "level": "INFO"}' | nc -u localhost 5000
echo "Log sent via UDP"
echo ""

# Method 4: Check Elasticsearch for logs
echo "4. Checking Elasticsearch for recent logs..."
sleep 2  # Wait a moment for Logstash to process
curl -s "http://localhost:9200/_cat/indices?v" | head -10
echo ""
echo "Searching for test logs..."
curl -s "http://localhost:9200/logstash-*/_search?q=*&size=5&sort=@timestamp:desc" | jq '.hits.hits[] | {timestamp: ._source["@timestamp"], message: ._source.message}' 2>/dev/null || echo "No logs found or jq not installed"
echo ""

echo "=== Test Complete ==="
echo ""
echo "To view logs in Kibana, go to: http://localhost:5601"
echo "To check Logstash logs: docker logs logstash"
