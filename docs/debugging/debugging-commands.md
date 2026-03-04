# Debugging Commands Used

## Container status
docker compose ps

## Exit code verification
docker inspect product-catalog --format='{{.State.ExitCode}}'

## Container logs
docker logs product-catalog

## Mounted directory check
ls src/product-catalog/products
