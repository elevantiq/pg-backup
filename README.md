# PostgreSQL Database Backup Docker Image

A Docker image for automated PostgreSQL database backups to AWS S3. This image is designed to be used as a service in Docker Swarm, allowing you to perform on-demand backups of multiple PostgreSQL databases.

## Features

- Backup multiple PostgreSQL databases in a single container
- Automatic upload to AWS S3
- Configurable via environment variables
- Designed for Docker Swarm deployment
- Zero replicas by default (runs only when scaled up)

## Usage

### Basic Configuration

Add the following service to your Docker Compose or stack file:

```yaml
database-backup:
  image: ghcr.io/dlhck/pg-backup:latest
  environment:
    S3_BUCKET: "your-backup-bucket"
    AWS_ACCESS_KEY_ID: "your-access-key"
    AWS_SECRET_ACCESS_KEY: "your-secret-key"
    AWS_REGION: "your-aws-region"
    PG_URLS: "db1=postgres://user:pass@host1:5432/db1,db2=postgres://user:pass@host2:5432/db2"
  deploy:
    replicas: 0 # Stays inactive until manually scaled
    restart_policy:
      condition: none
  networks:
    - your-network
```

### Environment Variables

| Variable                | Description                                                                              | Required |
| ----------------------- | ---------------------------------------------------------------------------------------- | -------- |
| `S3_BUCKET`             | AWS S3 bucket name for storing backups                                                   | Yes      |
| `AWS_ACCESS_KEY_ID`     | AWS access key ID                                                                        | Yes      |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key                                                                    | Yes      |
| `AWS_REGION`            | AWS region (e.g., 'eu-central-1')                                                        | Yes      |
| `PG_URLS`               | Comma-separated list of database URLs in format `name=postgres://user:pass@host:port/db` | Yes      |

### Network Configuration

The service needs to be attached to all networks where the target databases are located. The database host should be specified using the service alias combined with the stack name.

For example, if your database service is named `database` in a stack called `myapp`, the host in the PG_URLS should be `myapp_database`.

### Running Backups

By default, the service is configured with 0 replicas and won't run automatically. To trigger a backup:

1. Scale the service to 1 replica:

```bash
docker service scale <stack-name>_database-backup=1
```

2. The backup will run once and the service will automatically scale back to 0 replicas.

Example:

```bash
docker service scale maintenance_database-backup=1
```

### Scheduling Regular Backups

To run backups automatically every 3 hours, you can use cron. Here's how to set it up:

1. Create a cron job on your Docker Swarm manager node:

```bash
# Edit crontab
crontab -e
```

2. Add the following line to run backups every 3 hours:

```bash
0 */3 * * * docker service scale maintenance_database-backup=1
```

This will:

- Run at minute 0 of every 3rd hour (00:00, 03:00, 06:00, etc.)
- Scale the backup service to 1 replica, triggering a backup
- The service will automatically scale back to 0 after completion

Note: Make sure the cron daemon has access to the Docker socket. You might need to run the cron job as a user with Docker permissions or use `sudo`:

```bash
0 */3 * * * sudo docker service scale maintenance_database-backup=1
```

## Security Notes

- Store sensitive credentials (AWS keys, database passwords) securely
- Consider using Docker secrets for sensitive environment variables
- Ensure proper network isolation between services
- Use appropriate IAM roles and policies for S3 access

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
