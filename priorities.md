# Refocus Shell - Code Quality Priorities

## Overview
This document outlines the priority levels for addressing code quality issues identified in the comprehensive code sanity check. Items are organized by priority level and include rationale for prioritization decisions.

---

## 🚨 **HIGH PRIORITY** (Critical Security & Stability)

### 1. **SQL Injection Protection** 
- **Issue**: `sql_escape()` function exists but not used consistently
- **Risk**: Critical security vulnerability
- **Impact**: Database corruption, data loss, potential system compromise
- **Action**: Audit all SQL queries and ensure `sql_escape()` is used for all user inputs
- **Files affected**: All database operations in `lib/focus-db.sh` and command scripts

### 2. **Database Error Handling**
- **Issue**: Many database calls use `2>/dev/null` without proper error handling
- **Risk**: Silent failures, data corruption, debugging nightmares
- **Impact**: Users lose data without knowing why
- **Action**: Replace `2>/dev/null` with proper error logging to file while keeping terminal clean
- **Implementation**: Create centralized error logging system
- **Files affected**: All database operations across the codebase

---

## 🔧 **MEDIUM PRIORITY** (Consistency & Reliability)

### 3. **Error Code Standardization**
- **Issue**: Commands use different exit codes (0, 1) without clear pattern
- **Risk**: Script integration issues, unclear error states
- **Impact**: Difficult to determine success/failure programmatically
- **Action**: Define and implement consistent exit code strategy
- **Standard**: 
  - `0` = Success
  - `1` = General error
  - `2` = Invalid arguments
  - `3` = Database error
  - `4` = Permission error

### 4. **Exit Strategy Clarification**
- **Issue**: Mixed use of `exit 1` vs `return 1`
- **Rationale**: These serve different purposes:
  - `exit 1`: Terminates entire script (commands)
  - `return 1`: Returns from function (libraries)
- **Action**: Document when to use each pattern
- **Guidelines**:
  - Commands: Use `exit` for script termination
  - Libraries: Use `return` for function returns
  - Functions called by commands: Use `return`, let command handle `exit`

---

## 🔄 **LOW PRIORITY** (Enhancement & Consistency)

### 5. **Project Name Validation Consistency**
- **Issue**: `validate_project_name()` implemented but not used consistently
- **Action**: Expand usage across all commands that accept project names
- **Files**: All commands that take project names as arguments

### 6. **Timestamp Validation Approaches**
- **Issue**: Multiple different approaches across commands
- **Rationale**: Different validation approaches may be needed for different use cases
- **Action**: Document when each approach should be used
- **Status**: May be intentional design choice

### 7. **Duration Parsing Error Handling**
- **Issue**: Centralized in `focus-utils.sh` but error handling varies
- **Action**: Standardize error handling for duration parsing
- **Files**: Commands using duration parsing

### 8. **Database Schema Standardization**
- **Issue**: Table names and migration patterns need expansion
- **Action**: Further standardize database operations
- **Status**: Current implementation is good, needs minor improvements

---

## ⏳ **DEFERRED** (Future Improvements)

### 9. **Edge Case Handling**
- **Database corruption**: No handling for corrupted database files
- **Permission errors**: Limited handling for file permission issues
- **Disk space**: No checking for disk space before database operations
- **Rationale**: These are important but not blocking current functionality
- **Timeline**: Address after core stability issues are resolved

### 10. **Code Reuse Opportunities**
- **Duplicate validation**: Multiple commands implement similar validation logic
- **Duplicate error handling**: Similar error patterns repeated across commands
- **Duplicate output formatting**: Similar success/error message patterns
- **Duplicate database operations**: Similar query patterns across commands
- **Rationale**: Refactoring can be done incrementally without blocking features

### 11. **Function Documentation & Naming**
- **Minimal inline documentation**: Functions lack comprehensive documentation
- **Parameter validation**: Inconsistent parameter checking
- **Return values**: Inconsistent return value handling
- **Rationale**: Important for maintainability but not critical for functionality

---

## 🚫 **IGNORED** (Not Applicable)

### 12. **Network Issues**
- **Issue**: No handling for potential network-related database issues
- **Rationale**: Refocus Shell uses local SQLite database, no network operations
- **Status**: Not applicable to current architecture

### 13. **Concurrent Access**
- **Issue**: No locking mechanism for database access
- **Rationale**: Single-user tool, concurrent access not a concern
- **Status**: Not applicable to current use case

---

## 📋 **Implementation Notes**

### Priority Order
1. **High**: Items 1-2 (Security & Error Handling)
2. **Medium**: Items 3-4 (Consistency & Standards)
3. **Low**: Items 5-8 (Enhancement & Polish)
4. **Deferred**: Items 9-11 (Future Improvements)

### Implementation Strategy
- **High Priority**: Address immediately, these are security/stability risks
- **Medium Priority**: Address in next development cycle
- **Low Priority**: Address incrementally during feature development
- **Deferred**: Address during major refactoring phases

### Success Criteria
- **High Priority**: All SQL queries properly escaped, all database errors logged
- **Medium Priority**: Consistent exit codes, documented exit strategies
- **Low Priority**: Improved validation consistency, better error messages

---

## 🏷️ **Status Legend**
- 🚨 **High** - Critical security/stability issues
- 🔧 **Medium** - Consistency and reliability improvements
- 🔄 **Low** - Enhancement and polish
- ⏳ **Deferred** - Future improvements
- 🚫 **Ignored** - Not applicable

---

*Last updated: 2025-09-26*
*Total items: 13*
*High priority: 2*
*Medium priority: 2*
*Low priority: 4*
*Deferred: 3*
*Ignored: 2*
