# Deployment Notes

## Future Deployment Recommendations

### Use Podman Quadlet Templates

For future deployments, prefer **Podman Quadlet templates** over Docker Compose. Quadlet provides:

- **Systemd integration**: Native service management with `systemctl`
- **Automatic startup**: Services start with the system
- **Better security**: Runs as rootless by default
- **Simpler configuration**: YAML-based quadlet files
- **No external dependencies**: No need for separate compose binary

### Current Setup

The current wiki.js setup uses Docker Compose for maximum compatibility and ease of use across different environments. However, for production deployments on Linux systems with Podman, consider migrating to Quadlet templates.

### Example Quadlet Structure

When updating to Quadlet, the setup would look like:

```
/etc/containers/systemd/
├── wiki.container
├── nginx.container
└── wiki-data.volume
```

### Migration Path

1. Current: Docker Compose (cross-platform compatible)
2. Future: Podman Quadlet (Linux production-optimized)
3. Benefits: Better systemd integration, rootless containers, simpler management

### Related Resources

- [Podman Quadlet Documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
- [Quadlet Examples](https://github.com/containers/podman/tree/main/contrib/systemd/quadlet)
