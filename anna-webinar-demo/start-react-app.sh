#!/bin/bash

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================================${NC}"
echo -e "${GREEN}Starting Anna Webinar Demo with React Development Server${NC}"
echo -e "${BLUE}==================================================${NC}"

# Go to the project directory
cd "$(dirname "$0")"
echo -e "${YELLOW}Current directory: $(pwd)${NC}"

# Check if node is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed.${NC}"
    echo -e "Please install Node.js from https://nodejs.org/"
    exit 1
fi

# Make sure all dependencies are installed
echo -e "\n${YELLOW}Installing dependencies...${NC}"
npm install

# Create proper environment file for local development
echo -e "\n${YELLOW}Creating .env file for local development...${NC}"
cat > .env << EOL
# Local environment configuration
REACT_APP_API_URL=http://localhost:8000
REACT_APP_WS_URL=ws://localhost:8000
REACT_APP_ENV=development
EOL
echo -e "${GREEN}Environment file created.${NC}"

# Start the React development server
echo -e "\n${YELLOW}Starting React development server...${NC}"
echo -e "${GREEN}When ready, open http://localhost:3000 in your browser${NC}"
echo -e "${BLUE}==================================================${NC}"

npm start
