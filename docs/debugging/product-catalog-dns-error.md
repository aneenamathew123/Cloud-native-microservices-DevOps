## Troubleshooting Docker DNS resolution error

## Scenario:
While running a minimal stack of the opentelemetry ecommerce application, the frontend produced the following error:
" UNAVAILABLE: Name resolution failed for target dns:product-catalog:3550 " this indicated that the frontend service
was unable to resolve or reach the product-catalog service through Docker internal DNS network.

## Steps taken to troubleshoot

- Checked the  product-catalog contianer status "docker compose ps"
- Observed that the container crashes repeatedly and verfied the container exit code status.
- The product-catalog container exited with status 1 means application crashing during startup
- Checked the container logs and verfied the host directory src/product-catalog/products
- The directory was empty which caused the service to fail to startup.

## Root Cause Analysis:
- The product catalog service expects product data during startup.
In the minimal stack configuration, the database service was disabled to reduce resource usage,
Since the service couldn't retrieve product data, the application exited during initialization and caused 
the Docker DNS resolution problem

## Fix:
- Ensure that the product-catalog service has access to product data either by enabling the required database dependency, or
populating the products directory with the required JSON files.Once the service starts successfully, Docker DNS can 
resolve the service name correctly

## Key Takeaways:

- Docker DNS only resolves running containers
- Container exit codes are useful for diagnosing startup failures
- Service discovery errors often originate from downstream service crashes
- Checking service dependencies is an important step when troubleshooting distributed systems.
 
