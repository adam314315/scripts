# SCRIPT_SOFTS Directory

This directory contains software-specific installation modules:

- **n8n.sh** - n8n workflow automation installation
- **php.sh** - PHP programming language installation

Each software module should follow the naming convention:
- `{software}_menu()` - Display installation options
- `{software}_installation()` - Handle installation flow
- `install_{software}_{method}()` - Specific installation methods

To add a new software:
1. Create `{software}.sh` in this directory
2. Implement the required functions following the established patterns
3. Source the file in the main `script_setup.sh`
4. Add the software option to the main menu
