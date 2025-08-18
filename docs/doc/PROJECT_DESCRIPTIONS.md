# Project Descriptions

## Overview

Project descriptions provide optional context and clarity for your focus projects. They help you distinguish between similar projects, remember what a project was about months later, and provide better context in reports and exports.

## Features

- **Optional**: Descriptions are not required for projects to function
- **Lightweight**: Simple text descriptions without complex project management overhead
- **Integrated**: Descriptions appear in status, reports, and exports
- **Persistent**: Descriptions are stored in the database and survive restarts
- **Validated**: Input validation prevents empty descriptions and enforces length limits

## Commands

### `focus project set <project> <description>`

Set or update a project description.

```bash
# Set a new description
focus project set "coding" "Main development project for the web application"

# Update an existing description
focus project set "coding" "Updated description for the web application"

# Set description for a project that doesn't exist yet
focus project set "new-project" "This is a completely new project"
```

**Validation:**
- Project name cannot be empty
- Description cannot be empty
- Description cannot exceed 500 characters
- Project names are automatically sanitized

### `focus project show <project>`

View a project's description.

```bash
focus project show "coding"
```

**Output examples:**
```bash
# With description
📋 Project: coding
Description: Main development project for the web application

# Without description
📋 Project: coding
Description: No description set

To add a description, use: focus project set coding <description>
```

### `focus project list`

List all projects that have descriptions.

```bash
focus project list
```

**Output example:**
```bash
📋 Projects with Descriptions
============================

📋 coding
   Main development project for the web application

📋 meeting
   Client consultation and planning session

📋 refactor
   Refactoring the authentication system to use OAuth2
```

### `focus project remove <project>`

Remove a project's description.

```bash
focus project remove "coding"
```

**Output:**
```bash
✅ Description removed for project: coding
```

## Integration Points

### Status Display

Project descriptions appear in the `focus status` command when focusing on a project:

```bash
$ focus on coding
Started focus on: coding

$ focus status
⏳ Focusing on: coding — 0m elapsed
📋 Main development project for the web application
```

### Report Integration

Project descriptions are included in focus reports:

```bash
$ focus report today
📊 Today's Focus Report
=====================
Period: 2025-08-18

📈 Summary:
   Total focus time: 6h 30m
   Total sessions: 3
   Active projects: 2

📋 Project Breakdown:
   coding           2 sessions   4h 15m
                          Main development project for the web application
   meeting          1 sessions   2h 15m
                          Client consultation and planning session
```

### Export/Import

Project descriptions are included in data exports and imports:

```bash
$ focus export backup.sql
📤 Exporting focus data to: backup.sql
✅ Focus data exported successfully to: backup.sql
📊 Export contains:
   - Database schema
   - All focus sessions
   - Current focus state
   - Project descriptions
```

## Database Schema

Project descriptions are stored in a dedicated `projects` table:

```sql
CREATE TABLE projects (
    project TEXT PRIMARY KEY,
    description TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
```

**Fields:**
- `project`: Project name (primary key, references sessions.project)
- `description`: Project description text (required, max 500 characters)
- `created_at`: Timestamp when description was first created
- `updated_at`: Timestamp when description was last modified

## Migration

Existing databases are automatically migrated to include the projects table. The migration:

- Creates the `projects` table if it doesn't exist
- Preserves all existing data
- Requires no manual intervention
- Runs automatically when any focus command is executed

## Use Cases

### Distinguishing Similar Projects

```bash
# Without descriptions, these might be confusing
focus on "meeting"
focus on "meeting"

# With descriptions, clear context
focus project set "meeting" "Weekly team standup"
focus project set "meeting" "Client consultation for new project"
```

### Project Context for Future Self

```bash
# Set description when starting a complex project
focus project set "refactor" "Refactoring the authentication system to use OAuth2, replacing the old JWT implementation"

# Months later, you'll remember what this was about
focus project show "refactor"
```

### Better Reporting and Analysis

```bash
# Generate reports with context
focus report month

# See not just how much time, but what you were working on
📋 Project Breakdown:
   coding           15 sessions   45h 30m
                          Main development project for the web application
   refactor         8 sessions    22h 15m
                          Refactoring the authentication system to use OAuth2
```

### Team Collaboration

```bash
# Set descriptions for team projects
focus project set "backend" "Backend API development for the e-commerce platform"
focus project set "frontend" "React frontend for the e-commerce platform"
focus project set "testing" "Integration testing between frontend and backend"

# Share context with team members
focus project list
```

## Best Practices

### Writing Good Descriptions

- **Be specific**: "Web app development" vs "React frontend for e-commerce platform"
- **Include purpose**: "Client consultation for new project" vs "Client meeting"
- **Add context**: "Refactoring auth system to OAuth2" vs "Code refactoring"
- **Keep it concise**: Aim for 50-200 characters for readability

### When to Use Descriptions

- **Complex projects** that span multiple sessions
- **Similar project names** that could be confused
- **Long-term projects** that you'll return to later
- **Team projects** where context sharing is valuable
- **Client projects** where you need to remember details

### When Not to Use Descriptions

- **Simple, obvious projects** like "lunch" or "break"
- **One-time sessions** that won't be repeated
- **Very short descriptions** that don't add value
- **Overly detailed descriptions** that become maintenance overhead

## Troubleshooting

### Common Issues

**"Description is required"**
- Ensure you're providing both project name and description
- Check that the description isn't just whitespace

**"Description is too long (max 500 characters)"**
- Shorten your description to under 500 characters
- Consider breaking into multiple projects if needed

**Description not showing in status/reports**
- Ensure the project actually has a description set
- Use `focus project show <project>` to verify
- Check that you're using the updated command versions

**Database migration issues**
- Run `focus init` to reinitialize the database
- Check that the `projects` table exists: `sqlite3 ~/.local/refocus/refocus.db ".schema projects"`

## Examples

### Development Workflow

```bash
# Start a new feature
focus project set "feature-oauth" "Implementing OAuth2 authentication for the mobile app"
focus on feature-oauth

# Work on it
focus status
# Shows: ⏳ Focusing on: feature-oauth — 2h 15m elapsed
#        📋 Implementing OAuth2 authentication for the mobile app

# Stop for the day
focus off

# Next day, continue
focus on feature-oauth
# Continues with the same project and description
```

### Client Work

```bash
# Set up client projects
focus project set "client-a" "Website redesign for local restaurant"
focus project set "client-b" "E-commerce platform for handmade crafts"
focus project set "client-c" "Mobile app for fitness tracking"

# Work on different clients
focus on client-a
# ... work ...
focus off

focus on client-b
# ... work ...
focus off

# Generate client-specific reports
focus report custom 30  # Last 30 days
# Shows time breakdown with clear client context
```

### Learning Projects

```bash
# Track learning time
focus project set "rust-learning" "Learning Rust programming language through building a CLI tool"
focus project set "docker-study" "Studying Docker containers and Kubernetes orchestration"
focus project set "algorithm-practice" "Daily algorithm practice on LeetCode"

# Track progress over time
focus report month
# See how much time you've invested in each learning area
```

## Future Enhancements

The project descriptions feature is designed to be extensible. Future versions may include:

- **Markdown support** for richer descriptions
- **Search and filtering** by description text
- **Description templates** for common project types
- **Rich text editing** for longer descriptions
- **Tag system** for better organization
- **Description history** to track changes over time

## Contributing

If you have ideas for improving the project descriptions feature:

1. Check the [CLI ROADMAP.md](../CLI%20ROADMAP.md) for current development status
2. Open an issue to discuss the enhancement
3. Consider contributing code if it's a good fit
4. Test thoroughly before submitting pull requests

---

*Project descriptions help you focus better by providing context and clarity. Use them to make your time tracking more meaningful and your reports more insightful.*
