# Contributing to BBR Log Server

Thank you for your interest in contributing to BBR Log Server! This document provides guidelines and information for contributors.

## Code of Conduct

This project is committed to providing a welcoming and inclusive environment for all contributors. Please be respectful and constructive in all interactions.

## Getting Started

### Prerequisites

- Node.js 14.0.0 or higher
- npm or yarn package manager
- Git

### Development Setup

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/bbr-log-server.git
   cd bbr-log-server
   ```

3. **Install dependencies**:
   ```bash
   npm install
   ```

4. **Start the development server**:
   ```bash
   npm run dev
   ```

5. **Test your changes**:
   ```bash
   # Run the test script to generate sample logs
   chmod +x test_logs.sh
   ./test_logs.sh
   ```

## How to Contribute

### Reporting Issues

Before creating an issue, please:
- Check if the issue already exists
- Use the issue templates provided
- Include as much detail as possible (OS, Node.js version, error messages, etc.)

### Suggesting Enhancements

We welcome suggestions for new features and improvements. Please:
- Use the enhancement template
- Describe the use case and expected behavior
- Consider the impact on existing functionality

### Submitting Changes

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Write clean, readable code
   - Add comments for complex logic
   - Follow existing code style
   - Test your changes thoroughly

3. **Commit your changes**:
   ```bash
   git add .
   git commit -m "Add: brief description of changes"
   ```

4. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create a Pull Request**:
   - Use a descriptive title
   - Reference any related issues
   - Provide a clear description of changes
   - Include screenshots for UI changes

## Development Guidelines

### Code Style

- Use 2 spaces for indentation
- Use meaningful variable and function names
- Add JSDoc comments for functions
- Follow the existing code patterns

### File Structure

```
log_visualizer/
├── server.js              # Main server application
├── package.json           # Dependencies and scripts
├── Dockerfile            # Container configuration
├── README.md             # Project documentation
├── LICENSE               # AGPL-3.0 license
├── CONTRIBUTING.md       # This file
├── .gitignore            # Git ignore rules
└── public_html/          # Static web files
    ├── index.html        # Main web interface
    ├── poc.html          # Proof of concept page
    └── assets/
        ├── script.js     # Client-side JavaScript
        └── styles.css    # CSS styles
```

### Testing

- Test all new features thoroughly
- Ensure existing functionality still works
- Test with different log levels and message types
- Verify WebSocket connections work properly
- Test the Docker container build and run

### Documentation

- Update README.md for new features
- Add JSDoc comments for new functions
- Update API documentation if endpoints change
- Include examples for new functionality

## Areas for Contribution

- Performance optimizations
- Support for common log formats
- Enhanced error handling
- Security improvements
- Better mobile responsiveness
- Tests

## Pull Request Process

1. **Ensure your PR**:
   - Has a clear, descriptive title
   - Includes a detailed description
   - References any related issues
   - Has been tested thoroughly
   - Follows the coding standards

2. **Review process**:
   - All PRs require review
   - Address feedback promptly
   - Keep PRs focused and atomic
   - Update documentation as needed

3. **After approval**:
   - Maintainers will merge the PR
   - Your contribution will be credited
   - Thank you for helping improve the project!

## License

By contributing to this project, you agree that your contributions will be licensed under the same AGPL-3.0 license that covers the project.

## Questions?

If you have questions about contributing, please:
- Open an issue with the "question" label
- Contact the maintainers
- Check the existing documentation

## Recognition

Contributors will be recognized in:
- The project README
- Release notes
- The project's contributors list

Thank you for contributing to BBR Log Server! 🚀
