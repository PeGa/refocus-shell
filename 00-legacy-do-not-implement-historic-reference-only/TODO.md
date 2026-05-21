# Refocus Shell - TODO List

## Overview
This document tracks remaining improvements and future enhancements for Refocus Shell. Items are organized by priority and category.

---

## 🔧 Code Quality & Architecture (High Priority)

### Code Sanity & Refactoring
1. **Full code sanity check needed** - Hidden gems and inconsistencies throughout codebase
   - Review all scripts for consistency and best practices
   - Identify and fix any remaining edge cases
   - Standardize error handling patterns

2. **Concern separation needed** - Prevent "spahettification" of the project
   - Some commands still mix UI, business logic, and data access
   - Extract common patterns into reusable functions
   - Improve modularity between commands and libraries

3. **Code reuse opportunities** - Some code can be elegantly refactored for reuse
   - Consolidate duplicate validation logic
   - Extract common database operations
   - Standardize output formatting functions

### Prompt Management Issues
4. **Prompt update mechanism** - Current implementation has limitations
   - `focus status` should include time elapsed on current session
   - Need better prompt integration (study how virtualenv does it)
   - Current solutions have major pitfalls:
     - `alias work='. $(work)'` - kills bash session on uncatched -e
     - Subterminal approach - "flight-engineering-grade solution"
     - Moving to work function - requires major reengineering

### Input Validation & Error Handling
5. **Input validation enhancement** - Robust validation for all user inputs
   - Better handling of malformed data
   - Sanitization of project names and timestamps
   - Edge case handling for duration parsing
   - Improved error messages with actionable suggestions

6. **Project name collision handling** - Enhanced duplicate project name management
   - **Current state**: Basic continuation exists (`focus on` without project name continues last session)
   - **Enhancement needed**: Explicit collision detection when starting new session with existing project name
   - Should ask user whether to resume existing project or start new one
   - Need validation to prevent database collisions

---

## 🧪 Testing & Quality Assurance (High Priority)

### Testing Infrastructure
7. **Unit tests** - Test individual subcommands and library functions
   - Test `focus-db.sh`, `focus-utils.sh` libraries
   - Automated test suite with test framework
   - Mock database for isolated testing
   - Test error conditions and edge cases

8. **Integration tests** - Full workflow testing
   - Complete workflow: `focus on` → `focus status` → `focus off` → `focus report`
   - Database state validation
   - Cross-subcommand interactions
   - End-to-end user scenarios
   - Test pause/resume functionality

### Documentation
9. **API documentation** - Document libraries and functions
   - Developer guide for contributors
   - Code comments and inline documentation
   - Function parameter documentation
   - Database schema documentation

---

## 🚀 Feature Enhancements (Medium Priority)

### User Experience Improvements
10. **Enhanced error recovery** - Better error messages and recovery suggestions
    - Provide actionable steps when commands fail
    - Suggest common solutions for frequent issues
    - Improve error context and debugging information

11. **Interactive mode for complex operations** - User-friendly interfaces
    - Guided setup for complex configurations
    - Interactive project management
    - Step-by-step workflows for new users

12. **Auto-completion for shell integration** - Improved shell experience
    - Bash completion for project names
    - Tab completion for command options
    - Smart suggestions based on history

---

## 🔮 Future Features (Long-term)

### Advanced Functionality
13. **Automatic idle detection** - Stop tracking when device is idle
    - Privacy-safe, cross-distro compatible, opt-in
    - Support for KDE/Plasma, GNOME, X11, systemd-logind
    - Configurable idle thresholds

14. **Plugin system** - Allow custom subcommands via plugin directory
    - Hook system for events (session start/end)
    - Extensible architecture
    - Plugin management commands

15. **Backup & sync** - Automatic database backups
    - Cloud sync capabilities (Google Drive, Dropbox)
    - Data migration tools
    - Backup rotation and cleanup

### Advanced Features
16. **Time tracking templates** - Predefined session templates
17. **Project hierarchies and tags** - Better project organization
18. **External tool integration** - Jira, GitHub integration
19. **Web dashboard** - Visualization interface

### Performance & UX
20. **Performance optimization** - Database query optimization
    - Caching for frequently accessed data
    - Batch operations for large datasets
    - Memory usage optimization

21. **Enhanced user experience**
    - Progress indicators for long operations
    - Better error recovery suggestions
    - Improved reporting and analytics

---

## 📋 Implementation Notes

### Priority Order
1. **High**: Items 1-9 (code quality, testing, documentation)
2. **Medium**: Items 10-12 (user experience improvements)
3. **Future**: Items 13-21 (advanced features)

### Testing Strategy
- Each phase should include comprehensive testing
- Backward compatibility must be maintained
- User workflows should be validated

### Documentation Requirements
- All new features must be documented
- Examples should be provided for complex operations
- Breaking changes must be clearly communicated

---

## 🏷️ Status Legend
- 🔧 **High** - Important for code quality and testing
- 🚀 **Medium** - Feature enhancements
- 🔮 **Future** - Long-term roadmap

---

*Last updated: 2025-09-26*
*Total items: 21*
*High priority: 9*
*Medium priority: 3*
*Future items: 9*