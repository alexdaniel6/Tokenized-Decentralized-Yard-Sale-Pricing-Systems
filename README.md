# Tokenized Decentralized Yard Sale Pricing Systems

A comprehensive blockchain-based system for managing yard sales with automated pricing, negotiation tracking, inventory management, customer flow analysis, and donation coordination.

## System Overview

This system consists of five interconnected smart contracts that work together to create a fully decentralized yard sale management platform:

### Core Contracts

1. **Item Valuation Contract** (`item-valuation.clar`)
    - Suggests fair pricing based on item condition and market demand
    - Tracks historical pricing data
    - Implements dynamic pricing algorithms

2. **Negotiation Tracking Contract** (`negotiation-tracking.clar`)
    - Records successful bargaining strategies
    - Tracks negotiation patterns
    - Provides insights for future pricing decisions

3. **Inventory Management Contract** (`inventory-management.clar`)
    - Tracks sold and remaining merchandise
    - Manages item categories and descriptions
    - Handles inventory updates and status changes

4. **Customer Flow Contract** (`customer-flow.clar`)
    - Monitors peak shopping times and traffic patterns
    - Tracks customer engagement metrics
    - Provides analytics for optimal sale timing

5. **Donation Coordination Contract** (`donation-coordination.clar`)
    - Manages unsold item charitable distribution
    - Coordinates with registered charities
    - Tracks donation history and tax benefits

## Features

### Item Management
- Add items with detailed descriptions and conditions
- Automated fair price suggestions
- Real-time inventory tracking
- Category-based organization

### Pricing Intelligence
- Condition-based pricing algorithms
- Demand-driven price adjustments
- Historical price analysis
- Market trend integration

### Negotiation System
- Track successful bargaining patterns
- Record negotiation outcomes
- Analyze effective pricing strategies
- Customer behavior insights

### Analytics Dashboard
- Customer flow patterns
- Peak shopping time identification
- Sales performance metrics
- Inventory turnover rates

### Charitable Integration
- Automated donation coordination
- Charity verification system
- Tax benefit tracking
- Impact measurement

## Technical Architecture

### Smart Contract Design
- Written in Clarity for Stacks blockchain
- No cross-contract calls for security
- Independent contract operation
- Event-driven architecture

### Data Storage
- On-chain item metadata
- Pricing history preservation
- Customer interaction logs
- Donation transaction records

### Security Features
- Owner-only administrative functions
- Input validation and sanitization
- Error handling and recovery
- Access control mechanisms

## Getting Started

### Prerequisites
- Stacks blockchain node access
- Clarity development environment
- Testing framework setup

### Installation
1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts to testnet

### Usage Examples

#### Adding an Item
\`\`\`clarity
(contract-call? .item-valuation add-item
"Vintage Lamp"
"Electronics"
u8
u50)
\`\`\`

#### Recording a Sale
\`\`\`clarity
(contract-call? .inventory-management record-sale
u1
u45
'SP1234...)
\`\`\`

#### Tracking Customer Flow
\`\`\`clarity
(contract-call? .customer-flow log-visit
'SP5678...
u1640995200)
\`\`\`

## Testing

The system includes comprehensive test suites using Vitest:

- Unit tests for each contract function
- Integration tests for system workflows
- Edge case and error condition testing
- Performance and gas optimization tests

Run tests with:
\`\`\`bash
npm test
\`\`\`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For questions and support, please open an issue in the repository.
